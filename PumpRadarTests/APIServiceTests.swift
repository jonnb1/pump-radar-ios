// APIServiceTests.swift
// PumpRadarTests
//
// Tests for APIService URL construction, header injection, and error mapping.

import XCTest
import Combine
@testable import PumpRadar

// MARK: - MockURLProtocol

/// A URLProtocol subclass that intercepts requests for unit testing.
final class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - APIServiceTests

final class APIServiceTests: XCTestCase {

    private var sut: APIService!
    private var session: URLSession!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = APIService(
            baseURL: URL(string: "https://test.api")!,
            session: session,
            authToken: { "test-token" }
        )
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        cancellables.removeAll()
        sut = nil
        session = nil
        super.tearDown()
    }

    // MARK: - Auth Header

    func testAuthorizationHeaderIsAttached() {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let body = try JSONEncoder().encode(makePaginatedCoins())
            return (response, body)
        }
        let expectation = XCTestExpectation(description: "Request completed")
        sut.fetchCoins(page: 1, pageSize: 20)
            .sink { _ in } receiveValue: { _ in expectation.fulfill() }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }

    func testContentTypeHeaderIsSet() {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let body = try JSONEncoder().encode(makePaginatedCoins())
            return (response, body)
        }
        let expectation = XCTestExpectation(description: "Request completed")
        sut.fetchCoins(page: 1, pageSize: 20)
            .sink { _ in } receiveValue: { _ in expectation.fulfill() }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    // MARK: - HTTP Errors

    func test401ResponseMapsToUnauthorizedError() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let expectation = XCTestExpectation(description: "Unauthorized error received")
        sut.fetchCoins(page: 1, pageSize: 20)
            .sink { completion in
                if case .failure(let error) = completion, case .unauthorized = error {
                    expectation.fulfill()
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2)
    }

    func test500ResponseMapsToHTTPError() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, "Internal Server Error".data(using: .utf8)!)
        }
        let expectation = XCTestExpectation(description: "HTTP error received")
        sut.fetchCoins(page: 1, pageSize: 20)
            .sink { completion in
                if case .failure(let error) = completion, case .httpError(let code, _) = error {
                    XCTAssertEqual(code, 500)
                    expectation.fulfill()
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2)
    }

    // MARK: - Successful Decode

    func testFetchCoinsDecodesResponse() {
        let expectedCoins = makePaginatedCoins()
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let body = try encoder.encode(expectedCoins)
            return (response, body)
        }
        let expectation = XCTestExpectation(description: "Coins decoded")
        sut.fetchCoins(page: 1, pageSize: 20)
            .sink { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            } receiveValue: { response in
                XCTAssertEqual(response.items.count, 1)
                XCTAssertEqual(response.items.first?.symbol, "TEST")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2)
    }

    // MARK: - URL Construction

    func testFetchCoinsIncludesPageQueryParams() {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let body = try JSONEncoder().encode(makePaginatedCoins())
            return (response, body)
        }
        let expectation = XCTestExpectation(description: "Request completed")
        sut.fetchCoins(page: 2, pageSize: 50)
            .sink { _ in } receiveValue: { _ in expectation.fulfill() }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2)
        let components = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "page", value: "2")))
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "page_size", value: "50")))
    }
}

// MARK: - Test Helpers

private func makeCoin() -> Coin {
    Coin(
        id: "test-id", symbol: "TEST", name: "Test Coin",
        price: 0.001, priceChangePercent: 5.0,
        volume: 500_000, volumeChangePercent: 10.0,
        score: 40, stage: .early, signalChange: 2.0,
        reasonsFlagged: [], signalHistory: [], isFavorite: false
    )
}

private func makePaginatedCoins() -> PaginatedResponse<Coin> {
    PaginatedResponse(items: [makeCoin()], total: 1, page: 1, pageSize: 20, hasNextPage: false)
}
