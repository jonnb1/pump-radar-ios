// HomeView.swift
// PumpRadar
//
// The main screen showing a ranked list of suspicious coins, with search,
// filter, and sort controls.

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                content
                if viewModel.isLoading && viewModel.coins.isEmpty {
                    loadingOverlay
                }
            }
            .navigationTitle("Pump Radar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .searchable(text: $viewModel.searchText, prompt: "Search coins…")
            .refreshable { viewModel.refresh() }
        }
        .onAppear { viewModel.onAppear() }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.filteredCoins.isEmpty && !viewModel.isLoading {
            emptyState
        } else {
            coinList
        }
    }

    private var coinList: some View {
        List {
            // Filter chips
            filterSection

            // Coin rows
            ForEach(viewModel.filteredCoins) { coin in
                NavigationLink(destination: coinDetailDestination(coin: coin)) {
                    CoinRowView(coin: coin) {
                        handleWatchlistToggle(coin: coin)
                    }
                }
                .onAppear {
                    // Infinite scroll: load next page when last item appears
                    if coin.id == viewModel.filteredCoins.last?.id {
                        viewModel.loadNextPage()
                    }
                }
            }

            if viewModel.isLoading && !viewModel.coins.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }

            if let error = viewModel.errorMessage {
                errorRow(message: error)
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: viewModel.filteredCoins.map(\.id))
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Stage filters
                ForEach(ActivityStage.allCases, id: \.self) { stage in
                    FilterChip(
                        title: stage.displayName,
                        isSelected: viewModel.selectedStage == stage
                    ) {
                        viewModel.selectedStage = viewModel.selectedStage == stage ? nil : stage
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No coins found")
                .font(.headline)
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading coins…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func errorRow(message: String) -> some View {
        HStack {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button("Retry") { viewModel.refresh() }
                .font(.caption.bold())
        }
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Picker("Sort by", selection: $viewModel.sortOrder) {
                    ForEach(SortOrder.allCases) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
        }
    }

    // MARK: - Helpers

    private func coinDetailDestination(coin: Coin) -> some View {
        CoinDetailView(viewModel: CoinDetailViewModel(coin: coin))
    }

    private func handleWatchlistToggle(coin: Coin) {
        // Find the coin in the list and toggle its favorite state locally
        // The CoinDetailViewModel handles the API call; here we optimistically update
        if let index = viewModel.coins.firstIndex(where: { $0.id == coin.id }) {
            viewModel.coins[index].isFavorite.toggle()
        }
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    HomeView()
}
#endif
