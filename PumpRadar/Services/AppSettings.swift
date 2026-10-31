// AppSettings.swift
// On-device preferences. Demo mode starts on so the app works before a server exists.

import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults

    @Published var demoMode: Bool {
        didSet { defaults.set(demoMode, forKey: StorageKey.demoMode) }
    }

    @Published var apiBaseURL: String {
        didSet { defaults.set(apiBaseURL, forKey: StorageKey.apiBaseURL) }
    }

    @Published var proMode: Bool {
        didSet { defaults.set(proMode, forKey: StorageKey.proMode) }
    }

    @Published var alertsEnabled: Bool {
        didSet { defaults.set(alertsEnabled, forKey: StorageKey.alertsEnabled) }
    }

    @Published var alertThreshold: Int {
        didSet { defaults.set(alertThreshold, forKey: StorageKey.alertThreshold) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: StorageKey.demoMode) == nil {
            demoMode = true
        } else {
            demoMode = defaults.bool(forKey: StorageKey.demoMode)
        }
        apiBaseURL = defaults.string(forKey: StorageKey.apiBaseURL) ?? ""
        proMode = defaults.bool(forKey: StorageKey.proMode)
        alertsEnabled = defaults.bool(forKey: StorageKey.alertsEnabled)
        if defaults.object(forKey: StorageKey.alertThreshold) == nil {
            alertThreshold = 70
        } else {
            alertThreshold = defaults.integer(forKey: StorageKey.alertThreshold)
        }
    }
}
