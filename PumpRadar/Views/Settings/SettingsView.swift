// SettingsView.swift
// PumpRadar
//
// Allows users to configure detection thresholds, manage their account,
// and log out.

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {

    @ObservedObject var authViewModel: AuthViewModel
    @AppStorage(Constants.UserDefaultsKeys.volumeThreshold) var volumeThreshold: Double = 2.0
    @AppStorage(Constants.UserDefaultsKeys.priceThreshold) var priceThreshold: Double = 2.0
    @AppStorage(Constants.UserDefaultsKeys.socialThreshold) var socialThreshold: Double = 2.0
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                if let user = authViewModel.currentUser {
                    accountSection(user: user)
                }
                detectionSection
                aboutSection
                logoutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Sections

    private func accountSection(user: User) -> some View {
        Section(header: Text("Account")) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text(user.username)
                        .font(.headline)
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var detectionSection: some View {
        Section(
            header: Text("Detection Thresholds"),
            footer: Text("Adjust these values to tune sensitivity. Higher values make the detector more selective and reduce false positives.")
        ) {
            thresholdRow(
                label: "Volume",
                icon: "chart.bar.fill",
                value: $volumeThreshold
            )
            thresholdRow(
                label: "Price",
                icon: "dollarsign.circle",
                value: $priceThreshold
            )
            thresholdRow(
                label: "Social Mentions",
                icon: "person.2.wave.2",
                value: $socialThreshold
            )
        }
    }

    private var aboutSection: some View {
        Section(header: Text("About")) {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Build", value: buildNumber)
            Link(destination: URL(string: "https://pump-radar.io/privacy")!) {
                Label("Privacy Policy", systemImage: "lock.shield")
            }
            Link(destination: URL(string: "https://pump-radar.io/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
        .confirmationDialog(
            "Are you sure you want to sign out?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) { authViewModel.logout() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Helpers

    private func thresholdRow(label: String, icon: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: icon)
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.1f")× baseline")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Slider(value: value, in: 1...10, step: 0.5)
        }
        .padding(.vertical, 4)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SettingsView(authViewModel: {
        let vm = AuthViewModel()
        return vm
    }())
}
#endif
