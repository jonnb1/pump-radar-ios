// PumpRadarApp.swift
// Opens straight onto the board. Demo mode is on until a server URL is saved.

import SwiftUI

@main
struct PumpRadarApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var watchlist: WatchlistStore

    init() {
        _settings = StateObject(wrappedValue: MainActor.assumeIsolated { AppSettings() })
        _watchlist = StateObject(wrappedValue: MainActor.assumeIsolated { WatchlistStore() })
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(settings: settings, watchlist: watchlist)
        }
    }
}
