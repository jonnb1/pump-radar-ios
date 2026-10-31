// EventModels.swift
// Listings, ETF flow days, buzz spikes, and the other readings the feed can show.

import Foundation

enum EventKind: Equatable, CaseIterable {
    case listing
    case etfFlow
    case buzz
    case funding
    case divergence
    case sentiment
    case momentum
    case orderBook
    case other

    var title: String {
        switch self {
        case .listing: return "Listing"
        case .etfFlow: return "ETF flow"
        case .buzz: return "Buzz spike"
        case .funding: return "Funding"
        case .divergence: return "Divergence"
        case .sentiment: return "Sentiment"
        case .momentum: return "Momentum"
        case .orderBook: return "Order book"
        case .other: return "Note"
        }
    }

    var systemImage: String {
        switch self {
        case .listing: return "building.columns"
        case .etfFlow: return "arrow.left.arrow.right"
        case .buzz: return "bubble.left.and.bubble.right"
        case .funding: return "percent"
        case .divergence: return "arrow.triangle.branch"
        case .sentiment: return "gauge.with.dots.needle.33percent"
        case .momentum: return "chart.line.uptrend.xyaxis"
        case .orderBook: return "books.vertical"
        case .other: return "dot.circle"
        }
    }

    static func parse(_ raw: String) -> EventKind {
        let key = raw
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        switch key {
        case "listing", "listings", "new_listing":
            return .listing
        case "etf", "etf_flow", "etf_flows", "etfflow", "flow":
            return .etfFlow
        case "buzz", "buzz_spike", "x_buzz", "social", "social_buzz":
            return .buzz
        case "funding":
            return .funding
        case "divergence", "cross_exchange", "cross_exchange_divergence":
            return .divergence
        case "sentiment", "fear_greed", "fear_and_greed":
            return .sentiment
        case "momentum":
            return .momentum
        case "order_book", "orderbook", "book":
            return .orderBook
        default:
            return .other
        }
    }
}

enum EventFilter: String, CaseIterable, Identifiable {
    case all
    case listings
    case etfFlows
    case buzz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .listings: return "Listings"
        case .etfFlows: return "ETF flows"
        case .buzz: return "Buzz"
        }
    }

    func matches(_ kind: EventKind) -> Bool {
        switch self {
        case .all:
            return true
        case .listings:
            return kind == .listing
        case .etfFlows:
            return kind == .etfFlow
        case .buzz:
            return kind == .buzz
        }
    }
}

struct RadarEvent: Equatable, Identifiable, Decodable {
    let id: String
    let kind: EventKind
    let title: String
    let summary: String
    let symbol: String?
    let occurredAt: Date?
    let family: String?
    let source: String?

    init(
        id: String,
        kind: EventKind,
        title: String,
        summary: String,
        symbol: String? = nil,
        occurredAt: Date? = nil,
        family: String? = nil,
        source: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.summary = summary
        self.symbol = symbol
        self.occurredAt = occurredAt
        self.family = family
        self.source = source
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, type, title, summary, why, description
        case symbol, ticker, occurredAt, timestamp, time, family, source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawKind = container.decodeFlexString([.kind, .type]) ?? ""
        kind = EventKind.parse(rawKind)
        title = container.decodeFlexString([.title]) ?? kind.title
        summary = container.decodeFlexString([.summary, .why, .description]) ?? ""
        let decodedSymbol = container.decodeFlexString([.symbol, .ticker])
        symbol = decodedSymbol?.uppercased()
        occurredAt = container.decodeFlexDate([.occurredAt, .timestamp, .time])
        family = container.decodeFlexString([.family])
        source = container.decodeFlexString([.source])
        let explicitID = container.decodeFlexString([.id]) ?? ""
        if explicitID.isEmpty {
            id = "\(rawKind)|\(symbol ?? "")|\(title)"
        } else {
            id = explicitID
        }
    }
}

struct RadarEventsPage: Equatable, Decodable {
    let sample: Bool
    let sampleLabel: String?
    let events: [RadarEvent]

    static let empty = RadarEventsPage(sample: false, sampleLabel: nil, events: [])

    init(sample: Bool, sampleLabel: String?, events: [RadarEvent]) {
        self.sample = sample
        self.sampleLabel = sampleLabel
        self.events = events
    }

    private enum CodingKeys: String, CodingKey {
        case sample, sampleLabel, label, events, items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sample = container.decodeFlexBool([.sample]) ?? false
        sampleLabel = container.decodeFlexString([.sampleLabel, .label])
        if let events = try? container.decode([RadarEvent].self, forKey: .events) {
            self.events = events
        } else if let events = try? container.decode([RadarEvent].self, forKey: .items) {
            self.events = events
        } else {
            self.events = []
        }
    }

    func markedSample() -> RadarEventsPage {
        RadarEventsPage(
            sample: true,
            sampleLabel: sampleLabel ?? Copy.sampleBanner,
            events: events
        )
    }
}

struct SnapshotPoint: Equatable, Decodable {
    let timestamp: Date?
    let price: Double?
    let score: Int?

    init(timestamp: Date?, price: Double?, score: Int?) {
        self.timestamp = timestamp
        self.price = price
        self.score = score
    }

    private enum CodingKeys: String, CodingKey {
        case timestamp, time, price, value, score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = container.decodeFlexDate([.timestamp, .time])
        price = container.decodeFlexDouble([.price, .value])
        score = container.decodeFlexInt([.score])
    }
}

struct SnapshotSeries: Equatable, Decodable {
    let symbol: String
    let points: [SnapshotPoint]

    init(symbol: String, points: [SnapshotPoint]) {
        self.symbol = symbol
        self.points = points
    }

    private enum CodingKeys: String, CodingKey {
        case symbol, ticker, points, sparkline, prices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = (container.decodeFlexString([.symbol, .ticker]) ?? "").uppercased()
        if let points = try? container.decode([SnapshotPoint].self, forKey: .points) {
            self.points = points
        } else {
            let prices = container.decodeSparkline([.sparkline, .prices])
            self.points = prices.map { SnapshotPoint(timestamp: nil, price: $0, score: nil) }
        }
    }
}
