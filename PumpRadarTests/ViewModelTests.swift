// ViewModelTests.swift
// PumpRadarTests
//
// Unit tests for ViewModels using mock services to avoid real network calls.

import XCTest
import Combine
@testable import PumpRadar

// MARK: - Mock API Service

/// A test double for APIServiceProtocol that returns configurable responses.
final class MockAPIService: APIServiceProtocol {

    var coinsResult: Result<PaginatedResponse<Coin>, APIError> = .success(
        PaginatedResponse(items: Coin.sampleData, total: 3, page: 1, pageSize: 20, hasNextPage: false)
    )
    var coinResult: Result<Coin, APIError> = .success(.preview)
    var alertsResult: Result<[PumpAlert], APIError> = .success([.preview, .previewRead])
    var watchlistResult: Result<[Coin], APIError> = .success([.previewWatchlisted])
    var voidResult: Result<Void, APIError> = .success(())

    func fetchCoins(page: Int, pageSize: Int) -> AnyPublisher<PaginatedResponse<Coin>, APIError> {
        coinsResult.publisher.eraseToAnyPublisher()
    }
    func fetchCoin(id: String) -> AnyPublisher<Coin, APIError> {
        coinResult.publisher.eraseToAnyPublisher()
    }
    func fetchAlerts() -> AnyPublisher<[PumpAlert], APIError> {
        alertsResult.publisher.eraseToAnyPublisher()
    }
    func markAlertRead(id: String) -> AnyPublisher<Void, APIError> {
        voidResult.publisher.eraseToAnyPublisher()
    }
    func addToWatchlist(coinId: String) -> AnyPublisher<Void, APIError> {
        voidResult.publisher.eraseToAnyPublisher()
    }
    func removeFromWatchlist(coinId: String) -> AnyPublisher<Void, APIError> {
        voidResult.publisher.eraseToAnyPublisher()
    }
    func fetchWatchlist() -> AnyPublisher<[Coin], APIError> {
        watchlistResult.publisher.eraseToAnyPublisher()
    }
}

// MARK: - Mock Auth Service

final class MockAuthService: AuthServiceProtocol {

    private let userSubject: CurrentValueSubject<User?, Never>
    var loginResult: Result<User, APIError> = .success(.preview)
    var signUpResult: Result<User, APIError> = .success(.preview)
    var logoutCalled = false

    init(initialUser: User? = nil) {
        userSubject = CurrentValueSubject(initialUser)
    }

    var currentUser: AnyPublisher<User?, Never> { userSubject.eraseToAnyPublisher() }
    var isAuthenticated: Bool { userSubject.value != nil }

    func login(email: String, password: String) -> AnyPublisher<User, APIError> {
        if case .success(let user) = loginResult { userSubject.send(user) }
        return loginResult.publisher.eraseToAnyPublisher()
    }

    func signUp(email: String, username: String, password: String) -> AnyPublisher<User, APIError> {
        if case .success(let user) = signUpResult { userSubject.send(user) }
        return signUpResult.publisher.eraseToAnyPublisher()
    }

    func logout() {
        logoutCalled = true
        userSubject.send(nil)
    }

    func refreshTokenIfNeeded() -> AnyPublisher<Void, APIError> {
        Just(()).setFailureType(to: APIError.self).eraseToAnyPublisher()
    }
}

// MARK: - Result + Publisher

private extension Result where Failure == APIError {
    var publisher: AnyPublisher<Success, Failure> {
        switch self {
        case .success(let value):
            return Just(value).setFailureType(to: APIError.self).eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

// MARK: - HomeViewModelTests

@MainActor
final class HomeViewModelTests: XCTestCase {

    private var mockService: MockAPIService!
    private var viewModel: HomeViewModel!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockService = MockAPIService()
        viewModel = HomeViewModel(apiService: mockService)
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testOnAppearLoadsCoins() {
        let expectation = XCTestExpectation(description: "Coins loaded")
        viewModel.$coins
            .dropFirst()
            .sink { coins in
                XCTAssertFalse(coins.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        viewModel.onAppear()
        wait(for: [expectation], timeout: 2)
    }

    func testSearchFiltersBySymbol() {
        viewModel.coins = Coin.sampleData
        viewModel.searchText = "PEPE"
        XCTAssertEqual(viewModel.filteredCoins.count, 1)
        XCTAssertEqual(viewModel.filteredCoins.first?.symbol, "PEPE")
    }

    func testSearchFiltersByName() {
        viewModel.coins = Coin.sampleData
        viewModel.searchText = "example"
        XCTAssertEqual(viewModel.filteredCoins.count, 1)
        XCTAssertEqual(viewModel.filteredCoins.first?.symbol, "ABC")
    }

    func testSearchEmptyReturnsAll() {
        viewModel.coins = Coin.sampleData
        viewModel.searchText = ""
        XCTAssertEqual(viewModel.filteredCoins.count, Coin.sampleData.count)
    }

    func testStageFilterShowsOnlyMatchingCoins() {
        viewModel.coins = Coin.sampleData
        viewModel.selectedStage = .normal
        XCTAssertTrue(viewModel.filteredCoins.allSatisfy { $0.computedStage == .normal })
    }

    func testSortByScoreDescending() {
        viewModel.coins = Coin.sampleData
        viewModel.sortOrder = .scoreDescending
        let scores = viewModel.filteredCoins.map(\.score)
        XCTAssertEqual(scores, scores.sorted(by: >))
    }

    func testSortByScoreAscending() {
        viewModel.coins = Coin.sampleData
        viewModel.sortOrder = .scoreAscending
        let scores = viewModel.filteredCoins.map(\.score)
        XCTAssertEqual(scores, scores.sorted())
    }

    func testErrorLoadsFallbackDataInDebug() {
        mockService.coinsResult = .failure(.networkUnavailable)
        let expectation = XCTestExpectation(description: "Error shown or fallback loaded")
        viewModel.$errorMessage
            .compactMap { $0 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        viewModel.onAppear()
        wait(for: [expectation], timeout: 2)
    }

    func testRefreshResetsPage() {
        viewModel.currentPage = 3
        viewModel.refresh()
        // After refresh, currentPage should be reset to 1 when response arrives
        let expectation = XCTestExpectation(description: "Page reset")
        viewModel.$currentPage
            .filter { $0 == 1 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2)
    }
}

// MARK: - CoinDetailViewModelTests

@MainActor
final class CoinDetailViewModelTests: XCTestCase {

    private var mockService: MockAPIService!
    private var viewModel: CoinDetailViewModel!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockService = MockAPIService()
        viewModel = CoinDetailViewModel(coin: .preview, apiService: mockService)
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testRefreshUpdatesCoin() {
        let updated = Coin(
            id: "pepe", symbol: "PEPE", name: "Pepe Updated",
            price: 0.0000015, priceChangePercent: 20.0,
            volume: 2_000_000, volumeChangePercent: 300.0,
            score: 85, stage: .highRisk, signalChange: 15.0,
            reasonsFlagged: ["Updated reason"], signalHistory: [], isFavorite: false
        )
        mockService.coinResult = .success(updated)
        let expectation = XCTestExpectation(description: "Coin updated")
        viewModel.$coin
            .dropFirst()
            .sink { coin in
                XCTAssertEqual(coin.name, "Pepe Updated")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        viewModel.refresh()
        wait(for: [expectation], timeout: 2)
    }

    func testToggleWatchlistOptimisticallyUpdates() {
        XCTAssertFalse(viewModel.coin.isFavorite)
        viewModel.toggleWatchlist()
        XCTAssertTrue(viewModel.coin.isFavorite)
    }

    func testToggleWatchlistRevertsOnFailure() {
        mockService.voidResult = .failure(.httpError(statusCode: 500, message: "Server error"))
        let expectation = XCTestExpectation(description: "State reverted")
        viewModel.toggleWatchlist()
        XCTAssertTrue(viewModel.coin.isFavorite) // Optimistic update applied
        viewModel.$coin
            .dropFirst()
            .sink { coin in
                XCTAssertFalse(coin.isFavorite) // Reverted
                expectation.fulfill()
            }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2)
    }
}

// MARK: - WatchlistViewModelTests

@MainActor
final class WatchlistViewModelTests: XCTestCase {

    private var mockService: MockAPIService!
    private var viewModel: WatchlistViewModel!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockService = MockAPIService()
        viewModel = WatchlistViewModel(apiService: mockService)
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testLoadWatchlistPopulatesCoins() {
        let expectation = XCTestExpectation(description: "Watchlist loaded")
        viewModel.$watchlistCoins
            .dropFirst()
            .sink { coins in
                XCTAssertFalse(coins.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        viewModel.loadWatchlist()
        wait(for: [expectation], timeout: 2)
    }

    func testRemoveCoinOptimisticallyRemoves() {
        viewModel.watchlistCoins = [.previewWatchlisted]
        viewModel.removeCoin(.previewWatchlisted)
        XCTAssertTrue(viewModel.watchlistCoins.isEmpty)
    }

    func testAddCoinDoesNotDuplicate() {
        viewModel.watchlistCoins = [.previewWatchlisted]
        viewModel.addCoin(.previewWatchlisted)
        XCTAssertEqual(viewModel.watchlistCoins.count, 1)
    }
}

// MARK: - AlertsViewModelTests

@MainActor
final class AlertsViewModelTests: XCTestCase {

    private var mockService: MockAPIService!
    private var viewModel: AlertsViewModel!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockService = MockAPIService()
        viewModel = AlertsViewModel(apiService: mockService)
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testLoadAlertsPopulatesAlerts() {
        let expectation = XCTestExpectation(description: "Alerts loaded")
        viewModel.$alerts
            .dropFirst()
            .sink { alerts in
                XCTAssertFalse(alerts.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        viewModel.loadAlerts()
        wait(for: [expectation], timeout: 2)
    }

    func testMarkAsReadUpdatesLocalState() {
        viewModel.alerts = [.preview] // isRead = false
        viewModel.markAsRead(.preview)
        XCTAssertTrue(viewModel.alerts.first?.isRead ?? false)
    }

    func testMarkAllAsReadSetsAllRead() {
        viewModel.alerts = [.preview, .previewRead]
        viewModel.markAllAsRead()
        XCTAssertTrue(viewModel.alerts.allSatisfy(\.isRead))
    }

    func testUnreadCountReturnsCorrectValue() {
        viewModel.alerts = [.preview, .previewRead] // 1 unread
        XCTAssertEqual(viewModel.unreadCount, 1)
    }

    func testHasUnreadIsTrueWhenUnreadExists() {
        viewModel.alerts = [.preview]
        XCTAssertTrue(viewModel.hasUnread)
    }
}

// MARK: - AuthViewModelTests

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var mockAuthService: MockAuthService!
    private var viewModel: AuthViewModel!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testLoginFormValidWithValidCredentials() {
        viewModel.email = "user@example.com"
        viewModel.password = "securePass123"
        XCTAssertTrue(viewModel.isLoginFormValid)
    }

    func testLoginFormInvalidWithShortPassword() {
        viewModel.email = "user@example.com"
        viewModel.password = "short"
        XCTAssertFalse(viewModel.isLoginFormValid)
    }

    func testLoginFormInvalidWithEmptyEmail() {
        viewModel.email = ""
        viewModel.password = "securePass123"
        XCTAssertFalse(viewModel.isLoginFormValid)
    }

    func testSignUpFormInvalidWhenPasswordsMismatch() {
        viewModel.email = "user@example.com"
        viewModel.username = "user"
        viewModel.password = "password123"
        viewModel.confirmPassword = "different123"
        XCTAssertFalse(viewModel.isSignUpFormValid)
    }

    func testSignUpFormValidWithMatchingPasswords() {
        viewModel.email = "user@example.com"
        viewModel.username = "user"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        XCTAssertTrue(viewModel.isSignUpFormValid)
    }

    func testLoginSuccessSetsAuthenticated() {
        let expectation = XCTestExpectation(description: "Authenticated")
        viewModel.$isAuthenticated
            .filter { $0 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        viewModel.login()
        wait(for: [expectation], timeout: 2)
    }

    func testLoginFailureSetsErrorMessage() {
        mockAuthService.loginResult = .failure(.httpError(statusCode: 401, message: "Invalid credentials"))
        let expectation = XCTestExpectation(description: "Error set")
        viewModel.$errorMessage
            .compactMap { $0 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        viewModel.email = "user@example.com"
        viewModel.password = "wrongpassword"
        viewModel.login()
        wait(for: [expectation], timeout: 2)
    }

    func testLogoutCallsService() {
        viewModel.logout()
        XCTAssertTrue(mockAuthService.logoutCalled)
    }
}
