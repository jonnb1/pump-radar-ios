// Scorecard.swift
// Counts which families fired and which stayed quiet. A high score is a cluster, not a promise.

import Foundation

struct Scorecard: Equatable {
    let firedIDs: [String]
    let quietIDs: [String]
    let firedNames: [String]
    let quietNames: [String]
    let headline: String
    let detail: String
}

enum ScorecardBuilder {
    static func make(row: BoardRow, families: [SignalFamily]) -> Scorecard {
        let catalog = families.isEmpty ? SignalFamily.builtins : families
        let firedIDs = row.firedFamilyIDs
        let firedSet = Set(firedIDs)
        let quietIDs = catalog.map(\.id).filter { !firedSet.contains($0) }
        let firedNames = firedIDs.map { SignalFamily.displayName(for: $0, in: catalog) }
        let quietNames = quietIDs.map { SignalFamily.displayName(for: $0, in: catalog) }
        let headline = "\(firedIDs.count) of \(catalog.count) signal families fired"
        let detail = describe(firedNames: firedNames, quietNames: quietNames)
        return Scorecard(
            firedIDs: firedIDs,
            quietIDs: quietIDs,
            firedNames: firedNames,
            quietNames: quietNames,
            headline: headline,
            detail: detail
        )
    }

    private static func describe(firedNames: [String], quietNames: [String]) -> String {
        if firedNames.isEmpty {
            return "Nothing looks unusual against recent baselines."
        }
        if quietNames.isEmpty {
            return "Active: \(PlainEnglish.list(firedNames))."
        }
        return "Active: \(PlainEnglish.list(firedNames)). Quiet: \(PlainEnglish.list(quietNames))."
    }
}

struct RowPresentation: Equatable {
    let why: String
    let familyNames: [String]
    let proLines: [String]
}

enum RowPresenter {
    static func make(row: BoardRow, families: [SignalFamily], pro: Bool) -> RowPresentation {
        let names = unique(row.firedFamilyIDs.map { SignalFamily.displayName(for: $0, in: families) })
        return RowPresentation(
            why: PlainEnglish.why(for: row, families: families),
            familyNames: names,
            proLines: pro ? proLines(row: row, families: families) : []
        )
    }

    private static func proLines(row: BoardRow, families: [SignalFamily]) -> [String] {
        var lines: [String] = []
        if let price = row.price {
            var line = Formatting.price(price)
            if let change = row.priceChange24hPct {
                line += " · \(Formatting.signedPercent(change)) over 24h"
            }
            lines.append(line)
        }
        for signal in row.signals where signal.fired {
            let title = signal.name.isEmpty
                ? SignalFamily.displayName(for: signal.family, in: families)
                : signal.name
            lines.append("\(title) \(Int(signal.score.rounded()))")
        }
        if row.tradable {
            lines.append("Passes the data filter")
        }
        return lines
    }

    private static func unique(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names.filter { seen.insert($0).inserted }
    }
}
