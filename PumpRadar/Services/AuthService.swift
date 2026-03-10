// AuthService.swift
// PumpRadar
//
// Manages user authentication state, persists tokens in the Keychain, and
// exposes Combine publishers so the rest of the app can react to sign-in/out.

import Foundation
import Combine

// MARK: - AuthServiceProtocol

protocol AuthServiceProtocol {
    var currentUser: AnyPublisher<User?, Never> { get }
    var isAuthenticated: Bool { get }
    func login(email: String, password: String) -> AnyPublisher<User, APIError>
    func signUp(email: String, username: String, password: String) -> AnyPublisher<User, APIError>
    func logout()
    func refreshTokenIfNeeded() -> AnyPublisher<Void, APIError>
}

// MARK: - AuthService

final class AuthService: AuthServiceProtocol {

    // MARK: - Dependencies

    private let apiService: APIService
    private let keychain: KeychainService

    // MARK: - State

    private let userSubject = CurrentValueSubject<User?, Never>(nil)

    var currentUser: AnyPublisher<User?, Never> { userSubject.eraseToAnyPublisher() }

    var isAuthenticated: Bool { userSubject.value != nil }

    // MARK: - Initialiser

    init(
        apiService: APIService = APIService(),
        keychain: KeychainService = .shared
    ) {
        self.apiService = apiService
        self.keychain = keychain
        restoreSession()
    }

    // MARK: - AuthServiceProtocol

    func login(email: String, password: String) -> AnyPublisher<User, APIError> {
        let body = LoginRequest(email: email, password: password)
        return executeAuth(endpoint: "auth/login", body: body)
    }

    func signUp(email: String, username: String, password: String) -> AnyPublisher<User, APIError> {
        let body = SignUpRequest(email: email, username: username, password: password)
        return executeAuth(endpoint: "auth/register", body: body)
    }

    func logout() {
        keychain.delete(key: Constants.Keychain.authTokenKey)
        keychain.delete(key: Constants.Keychain.refreshTokenKey)
        userSubject.send(nil)
    }

    func refreshTokenIfNeeded() -> AnyPublisher<Void, APIError> {
        guard let refreshToken = keychain.read(key: Constants.Keychain.refreshTokenKey) else {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        let url = URL(string: Constants.API.baseURL)!.appendingPathComponent("auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.unknown($0) }
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw APIError.unauthorized
                }
                return data
            }
            .mapError { $0 as? APIError ?? APIError.unknown($0) }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .mapError { APIError.decodingFailed($0) }
            .handleEvents(receiveOutput: { [weak self] auth in
                self?.persist(auth: auth)
            })
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Private Helpers

    /// Calls an authentication endpoint (login or register) and persists tokens.
    private func executeAuth(endpoint: String, body: Encodable) -> AnyPublisher<User, APIError> {
        let url = URL(string: Constants.API.baseURL)!.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        } catch {
            return Fail(error: APIError.decodingFailed(error)).eraseToAnyPublisher()
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.unknown($0) }
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse else { throw APIError.noData }
                switch http.statusCode {
                case 200...299: return data
                case 401: throw APIError.unauthorized
                default:
                    let msg = String(data: data, encoding: .utf8) ?? "Unknown"
                    throw APIError.httpError(statusCode: http.statusCode, message: msg)
                }
            }
            .mapError { $0 as? APIError ?? APIError.unknown($0) }
            .decode(type: AuthResponse.self, decoder: decoder)
            .mapError { APIError.decodingFailed($0) }
            .handleEvents(receiveOutput: { [weak self] auth in
                self?.persist(auth: auth)
            })
            .map(\.user)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Saves tokens to the Keychain and updates the current user subject.
    private func persist(auth: AuthResponse) {
        keychain.save(value: auth.accessToken, key: Constants.Keychain.authTokenKey)
        keychain.save(value: auth.refreshToken, key: Constants.Keychain.refreshTokenKey)
        // Cache the user object so it can be restored on next launch
        let userEncoder = JSONEncoder()
        userEncoder.dateEncodingStrategy = .iso8601
        if let userData = try? userEncoder.encode(auth.user) {
            UserDefaults.standard.set(userData, forKey: "cachedUser")
        }
        userSubject.send(auth.user)
    }

    /// Attempts to restore a previous session from the Keychain by reading the
    /// stored user data. In a production app this would validate the token with
    /// the backend; here we treat the presence of a token as a valid session for
    /// the MVP.
    private func restoreSession() {
        guard keychain.read(key: Constants.Keychain.authTokenKey) != nil else { return }
        let userDecoder = JSONDecoder()
        userDecoder.dateDecodingStrategy = .iso8601
        if let userData = UserDefaults.standard.data(forKey: "cachedUser"),
           let user = try? userDecoder.decode(User.self, from: userData) {
            userSubject.send(user)
        }
    }
}

// MARK: - AnyEncodable Helper

/// Type-erasing wrapper for Encodable values, used when passing dynamic
/// request bodies to the JSON encoder.
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encodeFunc = wrapped.encode(to:) }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}
