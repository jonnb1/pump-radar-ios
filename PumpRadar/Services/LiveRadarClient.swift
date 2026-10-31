// LiveRadarClient.swift
// GET-only access to a configurable base URL.

import Foundation

struct LiveRadarClient: RadarClient {
    var baseURLString: String
    var session: URLSession = .shared

    func fetchBoard() async throws -> RadarBoard {
        try payload(RadarJSON.decodeBoard, from: try await get(RadarRoute.board))
    }

    func fetchEvents() async throws -> RadarEventsPage {
        try payload(RadarJSON.decodeEvents, from: try await get(RadarRoute.events))
    }

    func fetchFamilies() async throws -> [SignalFamily] {
        try payload(RadarJSON.decodeFamilies, from: try await get(RadarRoute.families))
    }

    func fetchSnapshots(symbol: String) async throws -> SnapshotSeries {
        let data = try await get(RadarRoute.snapshots, query: [URLQueryItem(name: "symbol", value: symbol)])
        let series = try payload(RadarJSON.decodeSnapshots, from: data)
        if let match = series.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
            return match
        }
        if series.count == 1 {
            return series[0]
        }
        return SnapshotSeries(symbol: symbol.uppercased(), points: [])
    }

    func fetchTradable() async throws -> TradablePage {
        try payload(RadarJSON.decodeTradable, from: try await get(RadarRoute.tradable))
    }

    private func get(_ path: String, query: [URLQueryItem] = []) async throws -> Data {
        guard let url = RadarPaths.url(base: baseURLString, path: path, query: query) else {
            throw RadarClientError.missingBaseURL
        }
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw RadarClientError.transport(
                "The server could not be reached. Check the API base URL, or turn Demo mode back on."
            )
        }
        guard let http = response as? HTTPURLResponse else {
            throw RadarClientError.transport("The server returned an unexpected response.")
        }
        guard (200...299).contains(http.statusCode) else {
            throw RadarClientError.http(http.statusCode)
        }
        return data
    }

    private func payload<T>(_ transform: (Data) throws -> T, from data: Data) throws -> T {
        do {
            return try transform(data)
        } catch let error as RadarClientError {
            throw error
        } catch {
            throw RadarClientError.decoding(error.localizedDescription)
        }
    }
}
