// Formatting.swift
// Quiet formatters for prices and lists. Percentages describe a move, not a result.

import Foundation

enum Formatting {
    static func price(_ value: Double) -> String {
        if value >= 1 {
            return String(format: "$%.2f", value)
        }
        if value >= 0.0001 {
            return String(format: "$%.6f", value)
        }
        return String(format: "$%.8f", value)
    }

    static func signedPercent(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }

    static func score(_ value: Int) -> String {
        "\(value)"
    }

    static func timestamp(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

enum PlainEnglish {
    /// Joins names as "a", "a and b", or "a, b, and c".
    static func list(_ items: [String]) -> String {
        switch items.count {
        case 0:
            return ""
        case 1:
            return items[0]
        case 2:
            return "\(items[0]) and \(items[1])"
        default:
            let head = items.dropLast().joined(separator: ", ")
            return "\(head), and \(items[items.count - 1])"
        }
    }

    static func why(for row: BoardRow, families: [SignalFamily]) -> String {
        let trimmed = row.why.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        let names = row.firedFamilyIDs.map { SignalFamily.displayName(for: $0, in: families) }
        if names.isEmpty {
            return "No signal family looks unusual right now, so the score stays low."
        }
        return "These readings are unusually active together: \(list(names)). That is why this row is on the board. It is not a forecast."
    }
}
