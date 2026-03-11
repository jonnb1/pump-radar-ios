// APIService.swift
// PumpRadar
//
// Centralised HTTP client for all backend API calls. Handles auth-header
// injection, JSON encoding/decoding, and maps HTTP error codes to APIError.

import Foundation
import Combine

// MARK: - APIServiceProtocol

/// Defines the public interface for the API service, enabling dependency
/// injection and unit-test mocking.
protocol APIServiceProtocol {
    func fetchCoins(page: Int, pageSize: Int) -> AnyPublisher<PaginatedResponse<Coin>, APIError>
    func fetchCoin(id: String) -> AnyPublisher<Coin, APIError>
    func fetchAlerts() -> AnyPublisher<[PumpAlert], APIError>
    func markAlertRead(id: String) -> AnyPublisher<Void, APIError>
    func addToWatchlist(coinId: String) -> AnyPublisher<Void, APIError>
    func removeFromWatchlist(coinId: String) -> AnyPublisher<Void, APIError>
    func fetchWatchlist() -> AnyPublisher<[Coin], APIError>
}

// MARK: - APIService

/// Concrete URLSession-backed implementation of `APIServiceProtocol`.
final class APIService: APIServiceProtocol {

    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let authToken: () -> String?

    // MARK: - Initialiser

    /// Creates an instance using the configured backend base URL.
    /// - Parameters:
    ///   - baseURL: Override for unit tests; defaults to Constants.API.baseURL.
    ///   - session: Override for unit tests; defaults to URLSession.shared.
    ///   - authToken: Closure that returns the current bearer token (lazy lookup).
    init(
        baseURL: URL = URL(string: Constants.API.baseURL)!,
        session: URLSession = .shared,
        authToken: @escaping () -> String? = { KeychainService.shared.read(key: Constants.Keychain.authTokenKey) }
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authToken = authToken
        self.decoder = {
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            return dec
        }()
    }

    // MARK: - APIServiceProtocol

    func fetchCoins(page: Int = 1, pageSize: Int = 20) -> AnyPublisher<PaginatedResponse<Coin>, APIError> {
        var components = URLComponents(url: baseURL.appendingPathComponent("coins"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        let request = buildRequest(url: components.url!, method: "GET")
        return execute(request: request, responseType: PaginatedResponse<Coin>.self)
    }

    func fetchCoin(id: String) -> AnyPublisher<Coin, APIError> {
        let url = baseURL.appendingPathComponent("coins/\(id)")
        let request = buildRequest(url: url, method: "GET")
        return execute(request: request, responseType: Coin.self)
    }

    func fetchAlerts() -> AnyPublisher<[PumpAlert], APIError> {
        let url = baseURL.appendingPathComponent("alerts")
        let request = buildRequest(url: url, method: "GET")
        return execute(request: request, responseType: [PumpAlert].self)
    }

    func markAlertRead(id: String) -> AnyPublisher<Void, APIError> {
        let url = baseURL.appendingPathComponent("alerts/\(id)/read")
        let request = buildRequest(url: url, method: "POST")
        return execute(request: request, responseType: Empty.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func addToWatchlist(coinId: String) -> AnyPublisher<Void, APIError> {
        let url = baseURL.appendingPathComponent("watchlist/\(coinId)")
        let request = buildRequest(url: url, method: "POST")
        return execute(request: request, responseType: WatchlistResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func removeFromWatchlist(coinId: String) -> AnyPublisher<Void, APIError> {
        let url = baseURL.appendingPathComponent("watchlist/\(coinId)")
        let request = buildRequest(url: url, method: "DELETE")
        return execute(request: request, responseType: WatchlistResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func fetchWatchlist() -> AnyPublisher<[Coin], APIError> {
        let url = baseURL.appendingPathComponent("watchlist")
        let request = buildRequest(url: url, method: "GET")
        return execute(request: request, responseType: [Coin].self)
    }

    // MARK: - Private Helpers

    /// Builds a URLRequest for the given URL and HTTP method, injecting the
    /// authorization header when a token is available.
    private func buildRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: Constants.API.timeoutInterval)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        return request
    }

    /// Executes a URL request, validates the HTTP status code, and decodes
    /// the JSON response body into the requested type.
    private func execute<T: Decodable>(
        request: URLRequest,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        session.dataTaskPublisher(for: request)
            .mapError { error -> APIError in
                if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    return .networkUnavailable
                }
                return .unknown(error)
            }
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.noData
                }
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                default:
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
                }
            }
            .mapError { error -> APIError in
                if let apiError = error as? APIError { return apiError }
                return .unknown(error)
            }
            .flatMap { data -> AnyPublisher<T, APIError> in
                // Handle Void / Empty responses that have no JSON body
                if T.self == Empty.self, let empty = Empty() as? T {
                    return Just(empty).setFailureType(to: APIError.self).eraseToAnyPublisher()
                }
                // Unwrap the standard APIResponse<T> envelope, falling back to
                // direct decoding for endpoints that return the payload directly.
                if let envelope = try? self.decoder.decode(APIResponse<T>.self, from: data),
                   let payload = envelope.data {
                    return Just(payload).setFailureType(to: APIError.self).eraseToAnyPublisher()
                }
                return Just(data)
                    .decode(type: T.self, decoder: self.decoder)
                    .mapError { APIError.decodingFailed($0) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Empty

/// Placeholder Decodable used when an endpoint returns no meaningful body.
struct Empty: Decodable {}
