// Constants.swift
// PumpRadar
//
// Central location for all app-wide constants including API configuration,
// notification identifiers, and UserDefaults keys.

import Foundation

/// App-wide constants organised by category.
enum Constants {
    // MARK: - API

    enum API {
        /// Base URL for the Pump Radar backend. Override in the environment
        /// by setting PUMP_RADAR_API_BASE_URL before building.
        static let baseURL: String = {
            if let url = ProcessInfo.processInfo.environment["PUMP_RADAR_API_BASE_URL"] {
                return url
            }
            return "https://api.pump-radar.io/v1"
        }()

        static let timeoutInterval: TimeInterval = 30
    }

    // MARK: - UserDefaults

    enum UserDefaultsKeys {
        static let watchlistSymbols = "watchlistSymbols"
        static let authToken = "authToken"
        static let volumeThreshold = "volumeThreshold"
        static let priceThreshold = "priceThreshold"
        static let socialThreshold = "socialThreshold"
    }

    // MARK: - Keychain

    enum Keychain {
        static let authTokenKey = "com.pumpradar.authToken"
        static let refreshTokenKey = "com.pumpradar.refreshToken"
    }

    // MARK: - Notifications

    enum NotificationCategories {
        static let pumpAlert = "PUMP_ALERT"
    }

    enum NotificationActions {
        static let viewDetails = "VIEW_DETAILS"
        static let dismiss = "DISMISS"
    }

    // MARK: - UI

    enum UI {
        static let cornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let animationDuration: Double = 0.3
    }

    // MARK: - Scoring

    enum Scoring {
        /// Score thresholds that determine the activity stage label.
        static let earlyThreshold = 30
        static let activeThreshold = 60
        static let highRiskThreshold = 80
    }
}
