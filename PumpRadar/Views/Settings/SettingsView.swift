// SettingsView.swift
// Demo mode, the API base URL, Simple or Pro, and the disclaimer.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                dataSection
                modeSection
                alertSection
                familySection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var dataSection: some View {
        Section {
            Toggle("Demo mode", isOn: $settings.demoMode)
            TextField("API base URL", text: $settings.apiBaseURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
        } header: {
            Text("Data")
        } footer: {
            Text(dataFooter)
        }
    }

    private var modeSection: some View {
        Section {
            Picker("Mode", selection: $settings.proMode) {
                Text("Simple").tag(false)
                Text("Pro").tag(true)
            }
            .pickerStyle(.segmented)
            Text(settings.proMode
                ? "Pro adds prices, per-family scores, quiet families, and the data-quality filter."
                : "Simple keeps each row to a score, the families that fired, and one sentence.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Reading level")
        }
    }

    private var alertSection: some View {
        Section {
            Toggle("Notify on this iPhone", isOn: $settings.alertsEnabled)
                .onChange(of: settings.alertsEnabled) { _, enabled in
                    if enabled {
                        Task { _ = await LocalAlertScheduler.requestAuthorization() }
                    }
                }
            Stepper(value: $settings.alertThreshold, in: 40...95, step: 5) {
                Text("When a watched score reaches \(settings.alertThreshold)")
            }
        } header: {
            Text("Local alerts")
        } footer: {
            Text("Optional. The alert stays on this iPhone when a coin you watch crosses the score. There is no remote push.")
        }
    }

    private var familySection: some View {
        Section {
            ForEach(SignalFamily.builtins) { family in
                VStack(alignment: .leading, spacing: 4) {
                    Text(family.name)
                        .font(.headline)
                    Text(family.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("What the families mean")
        }
    }

    private var aboutSection: some View {
        Section {
            Text(Copy.about)
                .fixedSize(horizontal: false, vertical: true)
            Text(Copy.disclaimer)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Version \(appVersion)")
                .foregroundStyle(.secondary)
        } header: {
            Text("About")
        }
    }

    private var dataFooter: String {
        """
        Demo mode uses sample JSON bundled in the app and labels every screen. \
        Turn it off and paste a server URL when the API is hosted. Paths used: \
        /radar/board, /radar/events, /radar/families, /radar/snapshots, and /signals/tradable.
        """
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
