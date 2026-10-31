// BoardViewModel.swift
// Loads the ranked board, merges the tradable filter, and keeps watch alerts on-device.

import Combine
import Foundation

@MainActor
final class BoardViewModel: ObservableObject {
    @Published private(set) var rows: [BoardRow] = []
    @Published private(set) var families: [SignalFamily] = SignalFamily.builtins
    @Published private(set) var isSample = false
    @Published private(set) var sampleLabel: String?
    @Published private(set) var marketNote: String?
    @Published private(set) var generatedAt: Date?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var searchText = ""
    @Published var watchlistOnly = false

    let settings: AppSettings
    let watchlist: WatchlistStore
    private let clientOverride: RadarClient?
    private let alerts: AlertScheduling
    private var notifiedKeys = Set<String>()

    init(
        settings: AppSettings,
        watchlist: WatchlistStore,
        client: RadarClient? = nil,
        alerts: AlertScheduling = LocalAlertScheduler()
    ) {
        self.settings = settings
        self.watchlist = watchlist
        self.clientOverride = client
        self.alerts = alerts
    }

    var visibleRows: [BoardRow] {
        rows.filter { row in
            if watchlistOnly && !watchlist.contains(row.symbol) {
                return false
            }
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !query.isEmpty else {
                return true
            }
            let sentence = PlainEnglish.why(for: row, families: families).lowercased()
            return row.symbol.lowercased().contains(query)
                || row.name.lowercased().contains(query)
                || sentence.contains(query)
        }
    }

    func presentation(for row: BoardRow) -> RowPresentation {
        RowPresenter.make(row: row, families: families, pro: settings.proMode)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let client = clientOverride ?? RadarClientFactory.make(settings: settings)
        do {
            let board = try await client.fetchBoard()
            let loadedFamilies = (try? await client.fetchFamilies()) ?? SignalFamily.builtins
            let tradable = (try? await client.fetchTradable()) ?? .empty
            apply(board: board, families: loadedFamilies, tradable: tradable)
            await considerAlerts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(board: RadarBoard, families: [SignalFamily], tradable: TradablePage) {
        let tradableSymbols = Set(tradable.signals.filter(\.tradable).map { $0.symbol.uppercased() })
        let merged = board.rows.map { row -> BoardRow in
            var copy = row
            if tradableSymbols.contains(row.symbol.uppercased()) {
                copy.tradable = true
            }
            return copy
        }
        self.families = families.isEmpty ? SignalFamily.builtins : families
        rows = merged.sorted(by: Self.ordered)
        isSample = board.sample
        sampleLabel = board.sampleLabel
        marketNote = board.marketNote
        generatedAt = board.generatedAt
    }

    private func considerAlerts() async {
        guard settings.alertsEnabled else {
            return
        }
        for row in rows where watchlist.contains(row.symbol) && row.score >= settings.alertThreshold {
            let key = "\(row.symbol)-\(row.score)"
            if notifiedKeys.contains(key) {
                continue
            }
            notifiedKeys.insert(key)
            await alerts.schedule(title: "\(row.symbol) is on the board", body: alertBody(for: row))
        }
    }

    private func alertBody(for row: BoardRow) -> String {
        let names = row.firedFamilyIDs.map { SignalFamily.displayName(for: $0, in: families) }
        let familyText: String
        if names.isEmpty {
            familyText = "No family is unusually active."
        } else if names.count == 1 {
            familyText = "\(names[0]) is active."
        } else {
            familyText = "\(PlainEnglish.list(names)) are active."
        }
        return "\(row.symbol) score is \(row.score). \(familyText) Open the app to read why. Not financial advice."
    }

    /// Ranked rows come first, in rank order. Rows without a rank follow, highest score first.
    static func ordered(_ lhs: BoardRow, _ rhs: BoardRow) -> Bool {
        let leftRank = lhs.rank ?? Int.max
        let rightRank = rhs.rank ?? Int.max
        if leftRank != rightRank {
            return leftRank < rightRank
        }
        if lhs.score != rhs.score {
            return lhs.score > rhs.score
        }
        return lhs.symbol < rhs.symbol
    }
}
