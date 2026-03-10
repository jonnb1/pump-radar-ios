// HomeViewModel.swift
// PumpRadar
//
// Manages the list of suspicious coins on the Home screen. Polls the API
// periodically and exposes filter/sort controls for the UI.

import Foundation
import Combine

// MARK: - SortOrder

enum SortOrder: String, CaseIterable, Identifiable {
    case scoreDescending = "Score ↓"
    case scoreAscending = "Score ↑"
    case priceChangeDescending = "Price Change ↓"
    case volumeChangeDescending = "Volume Change ↓"

    var id: String { rawValue }
}

// MARK: - HomeViewModel

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published State

    @Published var coins: [Coin] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedStage: ActivityStage?
    @Published var sortOrder: SortOrder = .scoreDescending
    @Published var currentPage = 1
    @Published var hasNextPage = false

    // MARK: - Dependencies

    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

    // MARK: - Computed Properties

    /// Coins after applying search, stage filter, and sort order.
    var filteredCoins: [Coin] {
        var result = coins
        if searchText.isNotEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.symbol.lowercased().contains(query) || $0.name.lowercased().contains(query)
            }
        }
        if let stage = selectedStage {
            result = result.filter { $0.computedStage == stage }
        }
        return result.sorted(by: sortComparator)
    }

    // MARK: - Initialiser

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }

    // MARK: - Actions

    /// Loads the first page of coins and starts periodic refresh.
    func onAppear() {
        loadCoins(page: 1)
        startPolling()
    }

    /// Loads the first page and stops any existing polling timer.
    func refresh() {
        currentPage = 1
        loadCoins(page: 1)
    }

    /// Loads the next page (for infinite scroll).
    func loadNextPage() {
        guard hasNextPage, !isLoading else { return }
        loadCoins(page: currentPage + 1)
    }

    // MARK: - Private Methods

    private func loadCoins(page: Int) {
        isLoading = true
        errorMessage = nil
        apiService.fetchCoins(page: page, pageSize: 20)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                    // Fall back to sample data in development
                    #if DEBUG
                    if self?.coins.isEmpty == true {
                        self?.coins = Coin.sampleData
                    }
                    #endif
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                if page == 1 {
                    self.coins = response.items
                } else {
                    self.coins.append(contentsOf: response.items)
                }
                self.currentPage = response.page
                self.hasNextPage = response.hasNextPage
            }
            .store(in: &cancellables)
    }

    /// Starts a 60-second timer that refreshes the coin list in the background.
    private func startPolling() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    private var sortComparator: (Coin, Coin) -> Bool {
        switch sortOrder {
        case .scoreDescending:
            return { $0.score > $1.score }
        case .scoreAscending:
            return { $0.score < $1.score }
        case .priceChangeDescending:
            return { $0.priceChangePercent > $1.priceChangePercent }
        case .volumeChangeDescending:
            return { $0.volumeChangePercent > $1.volumeChangePercent }
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension Coin {
    static let sampleData: [Coin] = [
        Coin.preview,
        Coin.previewWatchlisted,
        Coin(
            id: "abc",
            symbol: "ABC",
            name: "Example Coin",
            price: 0.045,
            priceChangePercent: 2.1,
            volume: 110_000,
            volumeChangePercent: 40.0,
            score: 25,
            stage: .normal,
            signalChange: 1.0,
            reasonsFlagged: [],
            signalHistory: [],
            isFavorite: false
        )
    ]
}
#endif
