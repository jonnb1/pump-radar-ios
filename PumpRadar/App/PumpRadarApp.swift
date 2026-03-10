// PumpRadarApp.swift
// PumpRadar
//
// Application entry point. Handles root navigation between the
// authentication flow and the main tab bar.

import SwiftUI

// MARK: - PumpRadarApp

@main
struct PumpRadarApp: App {

    // MARK: - State

    @StateObject private var authViewModel = AuthViewModel()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootView(authViewModel: authViewModel)
                .onAppear {
                    // Request notification permission at launch
                    _ = NotificationService.shared.requestAuthorization()
                }
        }
    }
}

// MARK: - RootView

/// Switches between the authentication flow and the main app based on
/// the current authentication state.
struct RootView: View {

    @ObservedObject var authViewModel: AuthViewModel
    @State private var showSignUp = false

    var body: some View {
        if authViewModel.isAuthenticated {
            MainTabView(authViewModel: authViewModel)
                .transition(.opacity)
        } else {
            authFlow
        }
    }

    @ViewBuilder
    private var authFlow: some View {
        NavigationView {
            VStack {
                LoginView(viewModel: authViewModel)
                NavigationLink(
                    "Create an account",
                    destination: SignUpView(viewModel: authViewModel)
                )
                .font(.subheadline)
                .padding(.bottom, 32)
            }
        }
        .transition(.opacity)
    }
}
