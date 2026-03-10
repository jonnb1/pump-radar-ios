// PumpAlert.swift
// PumpRadar
//
// Data model for pump detection alerts surfaced to the user.

import Foundation

// MARK: - Alert Severity

/// Indicates the urgency of a pump alert.
enum AlertSeverity: String, Codable {
    case low, medium, high, critical

    var displayName: String { rawValue.capitalized }

    var iconName: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.circle"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - PumpAlert

/// A single alert record generated when the pump score for a tracked coin changes.
struct PumpAlert: Identifiable, Codable {
    let id: String
    let coinId: String
    let coinSymbol: String
    let coinName: String
    let previousScore: Int
    let currentScore: Int
    let severity: AlertSeverity
    let message: String
    let createdAt: Date
    var isRead: Bool

    // MARK: - Computed Properties

    /// The score change expressed as an absolute delta.
    var scoreDelta: Int { currentScore - previousScore }

    /// Human-readable relative timestamp (e.g., "2 minutes ago").
    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, severity, message
        case coinId = "coin_id"
        case coinSymbol = "coin_symbol"
        case coinName = "coin_name"
        case previousScore = "previous_score"
        case currentScore = "current_score"
        case createdAt = "created_at"
        case isRead = "is_read"
    }
}

// MARK: - Preview Data

#if DEBUG
extension PumpAlert {
    static let preview = PumpAlert(
        id: "alert_001",
        coinId: "pepe",
        coinSymbol: "PEPE",
        coinName: "Pepe",
        previousScore: 45,
        currentScore: 72,
        severity: .high,
        message: "PEPE pump score jumped from 45 → 72. Volume is 3× the 24-hour baseline.",
        createdAt: Date().addingTimeInterval(-300),
        isRead: false
    )

    static let previewRead = PumpAlert(
        id: "alert_002",
        coinId: "dogeai",
        coinSymbol: "DOGEAI",
        coinName: "Doge AI",
        previousScore: 30,
        currentScore: 45,
        severity: .medium,
        message: "DOGEAI score rose from 30 → 45. Early-stage activity detected.",
        createdAt: Date().addingTimeInterval(-1800),
        isRead: true
    )
}
#endif
