// CoinDetailViewModel.swift
// One coin: the sentence, the scorecard, related events, and a price path when one exists.

import Combine
import Foundation

@MainActor
final class CoinDetailViewModel: ObservableObject {
    @Published private(set) var row: BoardRow
    @Published private(set) var events: [RadarEvent] = []
    @Published private(set) var sparkline: [Double]
    @Published private(set) var families: [SignalFamily]
    @Published private(set) var isLoading = false
    @Published private(set) var note: String?

    let watchlist: WatchlistStore
    private let settings: AppSettings
    private let clientOverride: RadarClient?

    init(
        row: BoardRow,
        families: [SignalFamily] = SignalFamily.builtins,
        settings: AppSettings,
        watchlist: WatchlistStore,
        client: RadarClient? = nil
    ) {
        self.row = row
        self.families = families.isEmpty ? SignalFamily.builtins : families
        self.sparkline = row.sparkline
        self.settings = settings
        self.watchlist = watchlist
        self.clientOverride = client
    }

    var why: String {
        PlainEnglish.why(for: row, families: families)
    }

    var scorecard: Scorecard {
        ScorecardBuilder.make(row: row, families: families)
    }

    var firedSignals: [SignalReading] {
        row.signals.filter(\.fired)
    }

    func toggleWatch() {
        watchlist.toggle(row.symbol)
    }

    func load() async {
        isLoading = true
        note = nil
        defer { isLoading = false }
        let client = clientOverride ?? RadarClientFactory.make(settings: settings)
        if let page = try? await client.fetchEvents() {
            events = page.events.filter { event in
                guard let symbol = event.symbol else {
                    return false
                }
                return symbol.caseInsensitiveCompare(row.symbol) == .orderedSame
            }
        }
        if sparkline.count < 2 {
            await loadSparkline(using: client)
        }
        if let latest = try? await client.fetchFamilies(), !latest.isEmpty {
            families = latest
        }
    }

    private func loadSparkline(using client: RadarClient) async {
        do {
            let series = try await client.fetchSnapshots(symbol: row.symbol)
            let prices = series.points.compactMap(\.price)
            if prices.count >= 2 {
                sparkline = prices
            }
        } catch {
            note = "A price path was not available."
        }
    }
}
