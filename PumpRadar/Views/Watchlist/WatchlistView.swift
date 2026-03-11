// WatchlistView.swift
// PumpRadar
//
// Displays the user's tracked coins and provides swipe-to-remove deletion.

import SwiftUI

// MARK: - WatchlistView

struct WatchlistView: View {

    @StateObject private var viewModel = WatchlistViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.watchlistCoins.isEmpty {
                    ProgressView("Loading watchlist…")
                } else if viewModel.watchlistCoins.isEmpty {
                    emptyState
                } else {
                    coinList
                }
            }
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { viewModel.loadWatchlist() }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear { viewModel.loadWatchlist() }
    }

    // MARK: - Subviews

    private var coinList: some View {
        List {
            ForEach(viewModel.watchlistCoins) { coin in
                NavigationLink(destination: CoinDetailView(viewModel: CoinDetailViewModel(coin: coin))) {
                    CoinRowView(coin: coin) {
                        viewModel.removeCoin(coin)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.removeCoin(coin)
                    } label: {
                        Label("Remove", systemImage: "star.slash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: viewModel.watchlistCoins.map(\.id))
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("No coins watched")
                .font(.title3.bold())
            Text("Tap the ★ on any coin to add it to your watchlist and receive real-time alerts.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    WatchlistView()
}
#endif
