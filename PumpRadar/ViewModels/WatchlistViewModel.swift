// WatchlistViewModel.swift
// PumpRadar
//
// Manages the user's watchlist: loading tracked coins, toggling membership,
// and persisting changes both locally and via the API.

import Foundation
import Combine

// MARK: - WatchlistViewModel

@MainActor
final class WatchlistViewModel: ObservableObject {

    // MARK: - Published State

    @Published var watchlistCoins: [Coin] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialiser

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }

    // MARK: - Actions

    /// Loads the user's current watchlist from the API.
    func loadWatchlist() {
        isLoading = true
        errorMessage = nil
        apiService.fetchWatchlist()
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                    #if DEBUG
                    if self?.watchlistCoins.isEmpty == true {
                        self?.watchlistCoins = [Coin.previewWatchlisted]
                    }
                    #endif
                }
            } receiveValue: { [weak self] coins in
                self?.watchlistCoins = coins
            }
            .store(in: &cancellables)
    }

    /// Removes a coin from the watchlist.
    func removeCoin(_ coin: Coin) {
        // Optimistic update
        watchlistCoins.removeAll { $0.id == coin.id }
        apiService.removeFromWatchlist(coinId: coin.id)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                    // Restore on failure
                    self?.watchlistCoins.append(coin)
                    self?.watchlistCoins.sort { $0.score > $1.score }
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    /// Adds a coin to the watchlist (called from other screens).
    func addCoin(_ coin: Coin) {
        guard !watchlistCoins.contains(where: { $0.id == coin.id }) else { return }
        var mutableCoin = coin
        mutableCoin.isFavorite = true
        watchlistCoins.append(mutableCoin)
        watchlistCoins.sort { $0.score > $1.score }
        apiService.addToWatchlist(coinId: coin.id)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                    self?.watchlistCoins.removeAll { $0.id == coin.id }
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
