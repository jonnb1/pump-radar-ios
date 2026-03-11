// Extensions.swift
// PumpRadar
//
// Convenience extensions on standard types used throughout the app.

import SwiftUI

// MARK: - Double

extension Double {
    /// Returns a compact price string. Values above 1 use 2 decimal places;
    /// very small values use up to 8 significant figures.
    var formattedPrice: String {
        if self >= 1 {
            return String(format: "$%.2f", self)
        } else if self >= 0.0001 {
            return String(format: "$%.6f", self)
        } else {
            return String(format: "$%.8f", self)
        }
    }

    /// Returns a compact volume string with K/M/B suffixes.
    var formattedVolume: String {
        switch self {
        case 1_000_000_000...:
            return String(format: "%.2fB", self / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.2fM", self / 1_000_000)
        case 1_000...:
            return String(format: "%.2fK", self / 1_000)
        default:
            return String(format: "%.2f", self)
        }
    }

    /// Returns a percentage string with a leading + sign for positive values.
    var formattedPercentage: String {
        let sign = self >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", self))%"
    }
}

// MARK: - Color

extension Color {
    /// Score-based colour: green for low, orange for medium, red for high.
    static func pumpScoreColor(score: Int) -> Color {
        switch score {
        case ..<30:
            return .green
        case 30..<60:
            return .orange
        default:
            return .red
        }
    }

    /// Colour for percentage change values.
    static func changeColor(value: Double) -> Color {
        value >= 0 ? .green : .red
    }
}

// MARK: - View

extension View {
    /// Applies a card-style background with rounded corners and a subtle shadow.
    func cardStyle() -> some View {
        self
            .padding(Constants.UI.cardPadding)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - String

extension String {
    /// Returns true when the string contains at least one non-whitespace character.
    var isNotEmpty: Bool { !trimmingCharacters(in: .whitespaces).isEmpty }
}
