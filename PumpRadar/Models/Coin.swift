// Coin.swift
// PumpRadar
//
// Data model for a tracked cryptocurrency asset.

import Foundation

// MARK: - Activity Stage

/// Describes the current pump detection stage for a coin.
enum ActivityStage: String, Codable, CaseIterable {
    case normal = "normal"
    case early = "early"
    case active = "active"
    case highRisk = "high_risk"

    /// A human-readable label shown in the UI.
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .early: return "Early"
        case .active: return "Active"
        case .highRisk: return "High Risk"
        }
    }

    /// SF Symbol name representing the stage.
    var iconName: String {
        switch self {
        case .normal: return "checkmark.circle"
        case .early: return "exclamationmark.circle"
        case .active: return "flame"
        case .highRisk: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Signal History Entry

/// A single historical signal score data point.
struct SignalHistoryEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let score: Int

    init(id: UUID = UUID(), timestamp: Date, score: Int) {
        self.id = id
        self.timestamp = timestamp
        self.score = score
    }
}

// MARK: - Coin

/// A cryptocurrency asset as returned by the backend API.
struct Coin: Identifiable, Codable {
    let id: String
    let symbol: String
    let name: String
    var price: Double
    var priceChangePercent: Double
    var volume: Double
    var volumeChangePercent: Double
    var score: Int
    var stage: ActivityStage
    var signalChange: Double
    var reasonsFlagged: [String]
    var signalHistory: [SignalHistoryEntry]
    var isFavorite: Bool

    // MARK: - Computed Properties

    /// Returns the activity stage derived from the pump score.
    var computedStage: ActivityStage {
        switch score {
        case ..<Constants.Scoring.earlyThreshold:
            return .normal
        case Constants.Scoring.earlyThreshold..<Constants.Scoring.activeThreshold:
            return .early
        case Constants.Scoring.activeThreshold..<Constants.Scoring.highRiskThreshold:
            return .active
        default:
            return .highRisk
        }
    }

    /// A formatted representation of the current price.
    var formattedPrice: String { price.formattedPrice }

    /// A formatted representation of the 24-hour volume.
    var formattedVolume: String { volume.formattedVolume }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, price, volume, score, stage
        case priceChangePercent = "price_change_percent"
        case volumeChangePercent = "volume_change_percent"
        case signalChange = "signal_change"
        case reasonsFlagged = "reasons_flagged"
        case signalHistory = "signal_history"
        case isFavorite = "is_favorite"
    }
}

// MARK: - Equatable

extension Coin: Equatable {
    static func == (lhs: Coin, rhs: Coin) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension Coin: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview Data

#if DEBUG
extension Coin {
    static let preview = Coin(
        id: "pepe",
        symbol: "PEPE",
        name: "Pepe",
        price: 0.000001234,
        priceChangePercent: 15.4,
        volume: 1_250_000,
        volumeChangePercent: 230.5,
        score: 72,
        stage: .active,
        signalChange: 12.0,
        reasonsFlagged: ["Volume spike >3x baseline", "Price momentum +15%", "Social mentions up 4x"],
        signalHistory: [
            SignalHistoryEntry(timestamp: Date().addingTimeInterval(-3600 * 5), score: 30),
            SignalHistoryEntry(timestamp: Date().addingTimeInterval(-3600 * 4), score: 45),
            SignalHistoryEntry(timestamp: Date().addingTimeInterval(-3600 * 3), score: 55),
            SignalHistoryEntry(timestamp: Date().addingTimeInterval(-3600 * 2), score: 65),
            SignalHistoryEntry(timestamp: Date().addingTimeInterval(-3600), score: 70),
            SignalHistoryEntry(timestamp: Date(), score: 72)
        ],
        isFavorite: false
    )

    static let previewWatchlisted = Coin(
        id: "dogeai",
        symbol: "DOGEAI",
        name: "Doge AI",
        price: 0.0012,
        priceChangePercent: 5.2,
        volume: 450_000,
        volumeChangePercent: 80.3,
        score: 45,
        stage: .early,
        signalChange: 5.0,
        reasonsFlagged: ["Volume up 1.8x baseline"],
        signalHistory: [
            SignalHistoryEntry(timestamp: Date().addingTimeInterval(-3600 * 2), score: 30),
            SignalHistoryEntry(timestamp: Date().addingTimeInterval(-3600), score: 38),
            SignalHistoryEntry(timestamp: Date(), score: 45)
        ],
        isFavorite: true
    )
}
#endif
