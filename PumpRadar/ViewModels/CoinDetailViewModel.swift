// CoinDetailViewModel.swift
// PumpRadar
//
// Fetches full details for a single coin and manages the watchlist toggle
// action for the detail screen.

import Foundation
import Combine

// MARK: - CoinDetailViewModel

@MainActor
final class CoinDetailViewModel: ObservableObject {

    // MARK: - Published State

    @Published var coin: Coin
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAddingToWatchlist = false

    // MARK: - Dependencies

    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialiser

    init(coin: Coin, apiService: APIServiceProtocol = APIService()) {
        self.coin = coin
        self.apiService = apiService
    }

    // MARK: - Actions

    /// Reloads the latest data for this coin from the API.
    func refresh() {
        isLoading = true
        errorMessage = nil
        apiService.fetchCoin(id: coin.id)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                }
            } receiveValue: { [weak self] updatedCoin in
                self?.coin = updatedCoin
            }
            .store(in: &cancellables)
    }

    /// Adds or removes the coin from the watchlist, toggling the local state
    /// optimistically so the UI responds immediately.
    func toggleWatchlist() {
        isAddingToWatchlist = true
        let publisher: AnyPublisher<Void, APIError> = coin.isFavorite
            ? apiService.removeFromWatchlist(coinId: coin.id)
            : apiService.addToWatchlist(coinId: coin.id)

        // Optimistic update
        coin.isFavorite.toggle()

        publisher
            .sink { [weak self] completion in
                self?.isAddingToWatchlist = false
                if case .failure(let error) = completion {
                    // Revert optimistic update on failure
                    self?.coin.isFavorite.toggle()
                    self?.errorMessage = error.errorDescription
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
