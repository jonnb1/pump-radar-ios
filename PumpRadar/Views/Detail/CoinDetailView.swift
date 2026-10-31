// CoinDetailView.swift
// Signal breakdown, recent events, and a sparkline when the feed has prices.

import SwiftUI

struct CoinDetailView: View {
    @StateObject private var viewModel: CoinDetailViewModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var watchlist: WatchlistStore
    private let sampleLabel: String?

    init(
        row: BoardRow,
        families: [SignalFamily],
        sampleLabel: String?,
        settings: AppSettings,
        watchlist: WatchlistStore
    ) {
        self.sampleLabel = sampleLabel
        _viewModel = StateObject(
            wrappedValue: MainActor.assumeIsolated {
                CoinDetailViewModel(
                    row: row,
                    families: families,
                    settings: settings,
                    watchlist: watchlist
                )
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let sampleLabel {
                    SampleBanner(text: sampleLabel)
                }
                whyBlock
                priceBlock
                scorecardBlock
                signalsBlock
                if settings.proMode {
                    quietBlock
                    filterBlock
                }
                eventsBlock
                watchButton
                DisclaimerFooter()
            }
            .padding()
        }
        .navigationTitle(viewModel.row.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .task { await viewModel.load() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.row.name)
                    .font(.title2.weight(.semibold))
                Text(viewModel.row.symbol)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ScoreBadge(score: viewModel.row.score)
        }
    }

    private var whyBlock: some View {
        Text(viewModel.why)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var priceBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent price")
                .font(.headline)
            if viewModel.sparkline.count >= 2 {
                SparklineView(values: viewModel.sparkline)
                    .padding(.vertical, 4)
                Text("A simple path of the prices included with this coin. It is not a forecast.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(viewModel.note ?? "No price path was included for this coin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var scorecardBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Scorecard")
                .font(.headline)
            Text(viewModel.scorecard.headline)
                .font(.subheadline.weight(.semibold))
            Text(viewModel.scorecard.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var signalsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What fired")
                .font(.headline)
            if viewModel.firedSignals.isEmpty {
                Text("No individual reading was attached to this row.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.firedSignals) { signal in
                    signalCard(signal)
                }
            }
        }
    }

    private func signalCard(_ signal: SignalReading) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(signal.displayName)
                .font(.subheadline.weight(.semibold))
            Text(signal.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if settings.proMode {
                Text("Family score \(Int(signal.score.rounded()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(Array(signal.metrics.enumerated()), id: \.offset) { _, metric in
                    Text("\(metric.label): \(metric.value)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let detail = signal.detail, detail != signal.summary {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var quietBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What stayed quiet")
                .font(.headline)
            let names = viewModel.scorecard.quietNames
            if names.isEmpty {
                Text("Every family in the catalog fired.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(PlainEnglish.list(names))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var filterBlock: some View {
        if viewModel.row.tradable {
            VStack(alignment: .leading, spacing: 6) {
                Text("Data filter")
                    .font(.headline)
                Text(Copy.dataFilterNote)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var eventsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent events")
                .font(.headline)
            if viewModel.events.isEmpty {
                Text("No listing, flow, or buzz event is attached to this coin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.events) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.subheadline.weight(.semibold))
                        Text(event.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var watchButton: some View {
        Button(watchlist.contains(viewModel.row.symbol) ? "Watching on this iPhone" : "Watch on this iPhone") {
            viewModel.toggleWatch()
        }
        .buttonStyle(.bordered)
        .accessibilityHint("Saves the coin on this iPhone. Does not trade.")
    }
}
