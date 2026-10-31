// DemoRadarClient.swift
// Serves the JSON files bundled with the app and always labels them as sample data.

import Foundation

final class BundleLocator {}

enum DemoBundle {
    static func data(named name: String) throws -> Data {
        let bundle = Bundle(for: BundleLocator.self)
        let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Demo")
            ?? bundle.url(forResource: name, withExtension: "json")
        guard let url else {
            throw RadarClientError.decoding("Missing sample file \(name).json")
        }
        return try Data(contentsOf: url)
    }
}

struct DemoRadarClient: RadarClient {
    func fetchBoard() async throws -> RadarBoard {
        try RadarJSON.decodeBoard(DemoBundle.data(named: "board")).markedSample()
    }

    func fetchEvents() async throws -> RadarEventsPage {
        try RadarJSON.decodeEvents(DemoBundle.data(named: "events")).markedSample()
    }

    func fetchFamilies() async throws -> [SignalFamily] {
        let families = try RadarJSON.decodeFamilies(DemoBundle.data(named: "families"))
        return families.isEmpty ? SignalFamily.builtins : families
    }

    func fetchSnapshots(symbol: String) async throws -> SnapshotSeries {
        let series = try RadarJSON.decodeSnapshots(DemoBundle.data(named: "snapshots"))
        if let match = series.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
            return match
        }
        return SnapshotSeries(symbol: symbol.uppercased(), points: [])
    }

    func fetchTradable() async throws -> TradablePage {
        var page = try RadarJSON.decodeTradable(DemoBundle.data(named: "tradable"))
        page = TradablePage(generatedAt: page.generatedAt, sample: true, signals: page.signals)
        return page
    }
}
