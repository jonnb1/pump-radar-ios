// BoardModels.swift
// Ranked board rows, per-family readings, and the tradable-filter list.

import Foundation

struct SignalMetric: Equatable, Identifiable, Decodable {
    let label: String
    let value: String

    var id: String { label }

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    private enum CodingKeys: String, CodingKey {
        case label, name, value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = container.decodeFlexString([.label, .name]) ?? "Reading"
        if let text = container.decodeFlexString([.value]) {
            value = text
        } else if let number = container.decodeFlexDouble([.value]) {
            value = SignalMetric.format(number)
        } else {
            value = ""
        }
    }

    private static func format(_ number: Double) -> String {
        if number.rounded() == number && abs(number) < 10_000 {
            return String(Int(number))
        }
        return String(format: "%.4g", number)
    }
}

struct SignalReading: Equatable, Identifiable, Decodable {
    let family: String
    let name: String
    let score: Double
    let fired: Bool
    let summary: String
    let detail: String?
    let metrics: [SignalMetric]

    var id: String { "\(family)|\(name)" }

    var displayName: String {
        name.isEmpty ? SignalFamily.displayName(for: family, in: []) : name
    }

    init(
        family: String,
        name: String,
        score: Double,
        fired: Bool,
        summary: String,
        detail: String? = nil,
        metrics: [SignalMetric] = []
    ) {
        self.family = family
        self.name = name
        self.score = score
        self.fired = fired
        self.summary = summary
        self.detail = detail
        self.metrics = metrics
    }

    private enum CodingKeys: String, CodingKey {
        case family, id, name, title, score, fired, active
        case summary, why, detail, explanation, metrics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedFamily = container.decodeFlexString([.family, .id]) ?? ""
        family = decodedFamily
        name = container.decodeFlexString([.name, .title]) ?? ""
        score = container.decodeFlexDouble([.score]) ?? 0
        fired = container.decodeFlexBool([.fired, .active]) ?? (score >= 60)
        let decodedSummary = container.decodeFlexString([.summary, .why]) ?? ""
        detail = container.decodeFlexString([.detail, .explanation])
        summary = decodedSummary.isEmpty ? (detail ?? "") : decodedSummary
        metrics = container.decodeMetrics([.metrics])
    }

    func fillingFamily(_ fallback: String) -> SignalReading {
        guard family.isEmpty else { return self }
        let resolvedName = name.isEmpty ? SignalFamily.displayName(for: fallback, in: []) : name
        return SignalReading(
            family: fallback,
            name: resolvedName,
            score: score,
            fired: fired,
            summary: summary,
            detail: detail,
            metrics: metrics
        )
    }
}

struct BoardRow: Equatable, Identifiable, Decodable {
    let assetId: String
    let symbol: String
    let name: String
    let score: Int
    let rank: Int?
    let price: Double?
    let priceChange24hPct: Double?
    let why: String
    let familiesFired: [String]
    let signals: [SignalReading]
    let sparkline: [Double]
    var tradable: Bool
    let updatedAt: Date?

    var id: String { assetId.isEmpty ? symbol : assetId }

    var firedFamilyIDs: [String] {
        if !familiesFired.isEmpty {
            return uniqueIDs(familiesFired)
        }
        return uniqueIDs(signals.filter(\.fired).map(\.family))
    }

    init(
        assetId: String,
        symbol: String,
        name: String,
        score: Int,
        rank: Int? = nil,
        price: Double? = nil,
        priceChange24hPct: Double? = nil,
        why: String,
        familiesFired: [String] = [],
        signals: [SignalReading] = [],
        sparkline: [Double] = [],
        tradable: Bool = false,
        updatedAt: Date? = nil
    ) {
        self.assetId = assetId
        self.symbol = symbol
        self.name = name
        self.score = score
        self.rank = rank
        self.price = price
        self.priceChange24hPct = priceChange24hPct
        self.why = why
        self.familiesFired = familiesFired
        self.signals = signals
        self.sparkline = sparkline
        self.tradable = tradable
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case assetId, id, symbol, ticker, name, score, rank, price
        case priceChange24hPct, priceChangePercent, change24h
        case why, summary, familiesFired, families, signals
        case sparkline, prices, tradable, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSymbol = container.decodeFlexString([.symbol, .ticker]) ?? ""
        symbol = decodedSymbol.uppercased()
        let decodedID = container.decodeFlexString([.assetId, .id]) ?? ""
        assetId = decodedID.isEmpty ? decodedSymbol.lowercased() : decodedID
        name = container.decodeFlexString([.name]) ?? decodedSymbol
        score = container.decodeFlexInt([.score]) ?? 0
        rank = container.decodeFlexInt([.rank])
        price = container.decodeFlexDouble([.price])
        priceChange24hPct = container.decodeFlexDouble([.priceChange24hPct, .priceChangePercent, .change24h])
        why = container.decodeFlexString([.why, .summary]) ?? ""
        signals = container.decodeSignals([.signals])
        let explicitFamilies = container.decodeStringList([.familiesFired, .families])
        familiesFired = explicitFamilies
        sparkline = container.decodeSparkline([.sparkline, .prices])
        tradable = container.decodeFlexBool([.tradable]) ?? false
        updatedAt = container.decodeFlexDate([.updatedAt])
    }
}

struct RadarBoard: Equatable, Decodable {
    let generatedAt: Date?
    let sample: Bool
    let sampleLabel: String?
    let marketNote: String?
    let rows: [BoardRow]

    init(
        generatedAt: Date?,
        sample: Bool,
        sampleLabel: String?,
        marketNote: String?,
        rows: [BoardRow]
    ) {
        self.generatedAt = generatedAt
        self.sample = sample
        self.sampleLabel = sampleLabel
        self.marketNote = marketNote
        self.rows = rows
    }

    private enum CodingKeys: String, CodingKey {
        case generatedAt, asOf, sample, sampleLabel, label, marketNote, note
        case rows, coins, items, board
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = container.decodeFlexDate([.generatedAt, .asOf])
        sample = container.decodeFlexBool([.sample]) ?? false
        sampleLabel = container.decodeFlexString([.sampleLabel, .label])
        marketNote = container.decodeFlexString([.marketNote, .note])
        if let rows = try? container.decode([BoardRow].self, forKey: .rows) {
            self.rows = rows
        } else if let rows = try? container.decode([BoardRow].self, forKey: .coins) {
            self.rows = rows
        } else if let rows = try? container.decode([BoardRow].self, forKey: .items) {
            self.rows = rows
        } else if let rows = try? container.decode([BoardRow].self, forKey: .board) {
            self.rows = rows
        } else {
            self.rows = []
        }
    }

    func markedSample() -> RadarBoard {
        RadarBoard(
            generatedAt: generatedAt,
            sample: true,
            sampleLabel: sampleLabel ?? Copy.sampleBanner,
            marketNote: marketNote,
            rows: rows
        )
    }
}

struct TradableSignal: Equatable, Identifiable, Decodable {
    let symbol: String
    let assetId: String?
    let score: Int
    let tradable: Bool
    let why: String
    let families: [String]

    var id: String { symbol }

    init(
        symbol: String,
        assetId: String? = nil,
        score: Int,
        tradable: Bool,
        why: String,
        families: [String] = []
    ) {
        self.symbol = symbol
        self.assetId = assetId
        self.score = score
        self.tradable = tradable
        self.why = why
        self.families = families
    }

    private enum CodingKeys: String, CodingKey {
        case symbol, ticker, assetId, id, score, tradable, why, summary, families, familiesFired
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = (container.decodeFlexString([.symbol, .ticker]) ?? "").uppercased()
        assetId = container.decodeFlexString([.assetId, .id])
        score = container.decodeFlexInt([.score]) ?? 0
        tradable = container.decodeFlexBool([.tradable]) ?? true
        why = container.decodeFlexString([.why, .summary]) ?? ""
        families = container.decodeStringList([.families, .familiesFired])
    }
}

struct TradablePage: Equatable, Decodable {
    let generatedAt: Date?
    let sample: Bool
    let signals: [TradableSignal]

    static let empty = TradablePage(generatedAt: nil, sample: false, signals: [])

    init(generatedAt: Date?, sample: Bool, signals: [TradableSignal]) {
        self.generatedAt = generatedAt
        self.sample = sample
        self.signals = signals
    }

    private enum CodingKeys: String, CodingKey {
        case generatedAt, asOf, sample, signals, rows, items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = container.decodeFlexDate([.generatedAt, .asOf])
        sample = container.decodeFlexBool([.sample]) ?? false
        if let signals = try? container.decode([TradableSignal].self, forKey: .signals) {
            self.signals = signals
        } else if let signals = try? container.decode([TradableSignal].self, forKey: .rows) {
            self.signals = signals
        } else if let signals = try? container.decode([TradableSignal].self, forKey: .items) {
            self.signals = signals
        } else {
            self.signals = []
        }
    }
}

private func uniqueIDs(_ ids: [String]) -> [String] {
    var seen = Set<String>()
    var ordered: [String] = []
    for id in ids where !id.isEmpty {
        if seen.insert(id).inserted {
            ordered.append(id)
        }
    }
    return ordered
}
