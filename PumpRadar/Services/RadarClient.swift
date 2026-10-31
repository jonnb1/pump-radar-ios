// RadarClient.swift
// Read-only client for the radar API. There is no order, wallet, or account call.

import Foundation

protocol RadarClient {
    func fetchBoard() async throws -> RadarBoard
    func fetchEvents() async throws -> RadarEventsPage
    func fetchFamilies() async throws -> [SignalFamily]
    func fetchSnapshots(symbol: String) async throws -> SnapshotSeries
    func fetchTradable() async throws -> TradablePage
}

enum RadarClientError: LocalizedError, Equatable {
    case missingBaseURL
    case transport(String)
    case http(Int)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            return "Add an API base URL in Settings, or turn Demo mode on to use the bundled sample board."
        case .transport(let message):
            return message
        case .http(let code):
            return "The server responded with status \(code). The board was not updated."
        case .decoding:
            return "The server responded, but the payload could not be read. Demo mode still works."
        }
    }
}

enum RadarPaths {
    static func url(base: String, path: String, query: [URLQueryItem] = []) -> URL? {
        var trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        if !trimmed.contains("://") {
            trimmed = "https://" + trimmed
        }
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard var components = URLComponents(string: trimmed + "/" + cleanPath) else {
            return nil
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        return components.url
    }
}

enum RadarClientFactory {
    @MainActor
    static func make(settings: AppSettings) -> RadarClient {
        if settings.demoMode {
            return DemoRadarClient()
        }
        return LiveRadarClient(baseURLString: settings.apiBaseURL)
    }
}
