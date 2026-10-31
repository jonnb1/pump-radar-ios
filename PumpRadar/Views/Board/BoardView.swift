// BoardView.swift
// The one-screen signal board.

import SwiftUI

struct BoardView: View {
    @ObservedObject var viewModel: BoardViewModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var watchlist: WatchlistStore

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.rows.isEmpty && viewModel.errorMessage == nil {
                    ProgressView("Loading the board")
                } else {
                    boardList
                }
            }
            .navigationTitle("Pump Radar")
            .toolbar { toolbar }
            .searchable(text: $viewModel.searchText, prompt: "Search coins")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .onChange(of: settings.demoMode) { _, _ in
                Task { await viewModel.load() }
            }
            .onChange(of: settings.apiBaseURL) { _, _ in
                Task { await viewModel.load() }
            }
        }
    }

    private var boardList: some View {
        List {
            if viewModel.isSample {
                Section {
                    SampleBanner(text: viewModel.sampleLabel ?? Copy.sampleBanner)
                }
            }
            if let note = viewModel.marketNote, !note.isEmpty {
                Section {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Section {
                Picker("Show", selection: $viewModel.watchlistOnly) {
                    Text("All").tag(false)
                    Text("Watching").tag(true)
                }
                .pickerStyle(.segmented)
            }
            if let error = viewModel.errorMessage {
                Section {
                    errorBlock(error)
                }
            }
            Section {
                rows
            } footer: {
                DisclaimerFooter()
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var rows: some View {
        if viewModel.visibleRows.isEmpty {
            Text(emptyTitle)
                .foregroundStyle(.secondary)
        } else {
            ForEach(viewModel.visibleRows) { row in
                NavigationLink {
                    CoinDetailView(
                        row: row,
                        families: viewModel.families,
                        sampleLabel: viewModel.isSample ? (viewModel.sampleLabel ?? Copy.sampleBanner) : nil,
                        settings: settings,
                        watchlist: watchlist
                    )
                } label: {
                    BoardRowView(
                        row: row,
                        presentation: viewModel.presentation(for: row),
                        watching: watchlist.contains(row.symbol)
                    )
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(watchlist.contains(row.symbol) ? "Unwatch" : "Watch") {
                        watchlist.toggle(row.symbol)
                    }
                    .tint(.indigo)
                }
            }
        }
    }

    private var emptyTitle: String {
        if viewModel.watchlistOnly {
            return "No watched coins on this board yet. Swipe a row and tap Watch."
        }
        if !viewModel.searchText.isEmpty {
            return "Nothing matches."
        }
        return "The board is empty."
    }

    private func errorBlock(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try again") {
                Task { await viewModel.load() }
            }
            if !settings.demoMode {
                Button("Use sample data") {
                    settings.demoMode = true
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(settings.proMode ? "Pro" : "Simple") {
                settings.proMode.toggle()
            }
            .accessibilityLabel(settings.proMode ? "Pro mode on" : "Simple mode on")
        }
    }
}
