// TestSupport.swift
// Shared fixtures for decoding and view-model tests.

import XCTest
@testable import PumpRadar

extension String {
    /// UTF-8 bytes for JSON fixtures. Avoids the optional `data(using:)` conversion.
    var utf8Data: Data { Data(utf8) }
}

enum TestSupport {
    static func defaults() throws -> UserDefaults {
        let name = "PumpRadar.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    static func fixture(_ name: String) throws -> Data {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("PumpRadar/Resources/Demo/\(name).json")
        return try Data(contentsOf: url)
    }

    static func row(
        symbol: String,
        score: Int,
        rank: Int? = nil,
        why: String = "",
        families: [String] = [],
        signals: [SignalReading] = [],
        sparkline: [Double] = [],
        tradable: Bool = false,
        price: Double? = nil
    ) -> BoardRow {
        BoardRow(
            assetId: symbol.lowercased(),
            symbol: symbol,
            name: symbol,
            score: score,
            rank: rank,
            price: price,
            why: why,
            familiesFired: families,
            signals: signals,
            sparkline: sparkline,
            tradable: tradable
        )
    }
}

final class FakeRadarClient: RadarClient {
    var board: Result<RadarBoard, Error>
    var events: Result<RadarEventsPage, Error> = .success(.empty)
    var families: Result<[SignalFamily], Error> = .success(SignalFamily.builtins)
    var snapshots: [SnapshotSeries] = []
    var tradable: Result<TradablePage, Error> = .success(.empty)

    init(board: RadarBoard) {
        self.board = .success(board)
    }

    func fetchBoard() async throws -> RadarBoard {
        try board.get()
    }

    func fetchEvents() async throws -> RadarEventsPage {
        try events.get()
    }

    func fetchFamilies() async throws -> [SignalFamily] {
        try families.get()
    }

    func fetchSnapshots(symbol: String) async throws -> SnapshotSeries {
        if let match = snapshots.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
            return match
        }
        return SnapshotSeries(symbol: symbol.uppercased(), points: [])
    }

    func fetchTradable() async throws -> TradablePage {
        try tradable.get()
    }
}

final class RecordingScheduler: AlertScheduling {
    var messages: [(title: String, body: String)] = []

    func schedule(title: String, body: String) async {
        messages.append((title, body))
    }
}
