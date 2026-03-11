// MainTabView.swift
// PumpRadar
//
// Root tab bar providing navigation between the Home, Watchlist,
// Alerts, and Settings screens.

import SwiftUI

// MARK: - MainTabView

struct MainTabView: View {

    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var alertsViewModel = AlertsViewModel()

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star")
                }

            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }
                .badge(alertsViewModel.unreadCount > 0 ? alertsViewModel.unreadCount : 0)

            SettingsView(authViewModel: authViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
            alertsViewModel.loadAlerts()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    MainTabView(authViewModel: AuthViewModel())
}
#endif
