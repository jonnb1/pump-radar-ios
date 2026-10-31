// RootTabView.swift
// Board, events, and settings. There is no trade tab.

import SwiftUI

struct RootTabView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var watchlist: WatchlistStore
    @StateObject private var boardViewModel: BoardViewModel
    @StateObject private var eventsViewModel: EventsViewModel

    init(settings: AppSettings, watchlist: WatchlistStore) {
        self.settings = settings
        self.watchlist = watchlist
        _boardViewModel = StateObject(
            wrappedValue: MainActor.assumeIsolated {
                BoardViewModel(settings: settings, watchlist: watchlist)
            }
        )
        _eventsViewModel = StateObject(
            wrappedValue: MainActor.assumeIsolated {
                EventsViewModel(settings: settings)
            }
        )
    }

    var body: some View {
        TabView {
            BoardView(viewModel: boardViewModel)
                .tabItem { Label("Board", systemImage: "list.bullet.rectangle") }
            EventsView(viewModel: eventsViewModel)
                .tabItem { Label("Events", systemImage: "dot.radiowaves.left.and.right") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .environmentObject(settings)
        .environmentObject(watchlist)
    }
}
