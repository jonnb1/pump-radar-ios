// RadarDecoding.swift
// Tolerant JSON decoding for the read-only radar endpoints.
// Canonical payloads use snake_case. camelCase and a `{ "data": ... }` envelope also decode.

import Foundation

enum RadarDates {
    static func parse(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: trimmed) {
            return date
        }
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        return basic.date(from: trimmed)
    }
}

enum RadarJSON {
    static func decodeBoard(_ data: Data) throws -> RadarBoard {
        let payload = unwrap(data)
        let decoder = makeDecoder()
        if jsonIsArray(payload), let rows = try? decoder.decode([BoardRow].self, from: payload) {
            return RadarBoard(generatedAt: nil, sample: false, sampleLabel: nil, marketNote: nil, rows: rows)
        }
        let board = try decoder.decode(RadarBoard.self, from: payload)
        if board.rows.isEmpty && !jsonHasAnyKey(payload, keys: boardKeys) && !board.sample {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "The board payload did not include any coins.")
            )
        }
        return board
    }

    static func decodeEvents(_ data: Data) throws -> RadarEventsPage {
        let payload = unwrap(data)
        let decoder = makeDecoder()
        if jsonIsArray(payload), let events = try? decoder.decode([RadarEvent].self, from: payload) {
            return RadarEventsPage(sample: false, sampleLabel: nil, events: events)
        }
        return try decoder.decode(RadarEventsPage.self, from: payload)
    }

    static func decodeFamilies(_ data: Data) throws -> [SignalFamily] {
        let payload = unwrap(data)
        let decoder = makeDecoder()
        if jsonIsArray(payload), let families = try? decoder.decode([SignalFamily].self, from: payload) {
            return families
        }
        let page = try decoder.decode(FamilyPage.self, from: payload)
        if page.families.isEmpty && !jsonHasAnyKey(payload, keys: ["families", "items"]) {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "The families payload was empty.")
            )
        }
        return page.families
    }

    static func decodeSnapshots(_ data: Data) throws -> [SnapshotSeries] {
        let payload = unwrap(data)
        let decoder = makeDecoder()
        if jsonIsArray(payload), let series = try? decoder.decode([SnapshotSeries].self, from: payload) {
            return series
        }
        if let page = try? decoder.decode(SnapshotPage.self, from: payload),
           jsonHasAnyKey(payload, keys: ["snapshots", "series", "items"]) {
            return page.snapshots
        }
        if let one = try? decoder.decode(SnapshotSeries.self, from: payload) {
            return [one]
        }
        return try decoder.decode(SnapshotPage.self, from: payload).snapshots
    }

    static func decodeTradable(_ data: Data) throws -> TradablePage {
        let payload = unwrap(data)
        let decoder = makeDecoder()
        if jsonIsArray(payload), let signals = try? decoder.decode([TradableSignal].self, from: payload) {
            return TradablePage(generatedAt: nil, sample: false, signals: signals)
        }
        return try decoder.decode(TradablePage.self, from: payload)
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(decodeDate)
        return decoder
    }

    private static func decodeDate(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            if let date = RadarDates.parse(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognised date")
        }
        if let seconds = try? container.decode(Double.self) {
            return Date(timeIntervalSince1970: seconds)
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognised date")
    }

    private static let boardKeys = [
        "rows", "coins", "items", "board", "generated_at", "generatedAt", "market_note", "marketNote"
    ]

    static func unwrap(_ data: Data) -> Data {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return data
        }
        let envelope: Set<String> = ["data", "result", "success", "error", "message", "ok"]
        guard Set(object.keys).isSubset(of: envelope) else {
            return data
        }
        guard let inner = object["data"] ?? object["result"] else {
            return data
        }
        guard JSONSerialization.isValidJSONObject(inner),
              let innerData = try? JSONSerialization.data(withJSONObject: inner) else {
            return data
        }
        return innerData
    }

    private static func jsonIsArray(_ data: Data) -> Bool {
        (try? JSONSerialization.jsonObject(with: data)) is [Any]
    }

    private static func jsonHasAnyKey(_ data: Data, keys: [String]) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return !Set(keys).isDisjoint(with: object.keys)
    }
}

private struct FamilyPage: Decodable {
    let families: [SignalFamily]

    private enum CodingKeys: String, CodingKey {
        case families, items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let families = try? container.decode([SignalFamily].self, forKey: .families) {
            self.families = families
        } else if let families = try? container.decode([SignalFamily].self, forKey: .items) {
            self.families = families
        } else {
            self.families = []
        }
    }
}

private struct SnapshotPage: Decodable {
    let snapshots: [SnapshotSeries]

    private enum CodingKeys: String, CodingKey {
        case snapshots, series, items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let snapshots = try? container.decode([SnapshotSeries].self, forKey: .snapshots) {
            self.snapshots = snapshots
        } else if let snapshots = try? container.decode([SnapshotSeries].self, forKey: .series) {
            self.snapshots = snapshots
        } else if let snapshots = try? container.decode([SnapshotSeries].self, forKey: .items) {
            self.snapshots = snapshots
        } else {
            self.snapshots = []
        }
    }
}

private struct FamilyStub: Decodable {
    let id: String?
    let family: String?

    private enum CodingKeys: String, CodingKey {
        case id, family
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFlexString([.id])
        family = container.decodeFlexString([.family])
    }
}

private struct SparkPoint: Decodable {
    let price: Double?

    private enum CodingKeys: String, CodingKey {
        case price, value, close
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        price = container.decodeFlexDouble([.price, .value, .close])
    }
}

extension KeyedDecodingContainer {
    func decodeFlexString(_ keys: [Key]) -> String? {
        for key in keys {
            if let value = try? decode(String.self, forKey: key) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }

    func decodeFlexInt(_ keys: [Key]) -> Int? {
        for key in keys {
            if let value = try? decode(Int.self, forKey: key) {
                return value
            }
            if let value = try? decode(Double.self, forKey: key) {
                return Int(value.rounded())
            }
            if let value = try? decode(String.self, forKey: key), let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    func decodeFlexDouble(_ keys: [Key]) -> Double? {
        for key in keys {
            if let value = try? decode(Double.self, forKey: key) {
                return value
            }
            if let value = try? decode(Int.self, forKey: key) {
                return Double(value)
            }
            if let value = try? decode(String.self, forKey: key), let doubleValue = Double(value) {
                return doubleValue
            }
        }
        return nil
    }

    func decodeFlexBool(_ keys: [Key]) -> Bool? {
        for key in keys {
            if let value = try? decode(Bool.self, forKey: key) {
                return value
            }
            if let value = try? decode(Int.self, forKey: key) {
                return value != 0
            }
            if let value = try? decode(String.self, forKey: key) {
                switch value.lowercased() {
                case "true", "yes", "1":
                    return true
                case "false", "no", "0":
                    return false
                default:
                    break
                }
            }
        }
        return nil
    }

    func decodeFlexDate(_ keys: [Key]) -> Date? {
        for key in keys {
            if let date = try? decode(Date.self, forKey: key) {
                return date
            }
            if let seconds = try? decode(Double.self, forKey: key) {
                return Date(timeIntervalSince1970: seconds)
            }
        }
        return nil
    }

    func decodeStringList(_ keys: [Key]) -> [String] {
        for key in keys {
            if let values = try? decode([String].self, forKey: key) {
                return values.filter { !$0.isEmpty }
            }
            if let stubs = try? decode([FamilyStub].self, forKey: key) {
                let ids = stubs.compactMap { $0.id ?? $0.family }
                if !ids.isEmpty {
                    return ids
                }
            }
        }
        return []
    }

    func decodeSignals(_ keys: [Key]) -> [SignalReading] {
        for key in keys {
            if let readings = try? decode([SignalReading].self, forKey: key) {
                return readings
            }
            if let keyed = try? decode([String: SignalReading].self, forKey: key) {
                return keyed
                    .map { pair in pair.value.fillingFamily(pair.key) }
                    .sorted { $0.family < $1.family }
            }
        }
        return []
    }

    func decodeMetrics(_ keys: [Key]) -> [SignalMetric] {
        for key in keys {
            if let metrics = try? decode([SignalMetric].self, forKey: key) {
                return metrics
            }
            if let strings = try? decode([String: String].self, forKey: key) {
                return strings
                    .map { SignalMetric(label: prettifyMetricKey($0.key), value: $0.value) }
                    .sorted { $0.label < $1.label }
            }
            if let numbers = try? decode([String: Double].self, forKey: key) {
                return numbers
                    .map { SignalMetric(label: prettifyMetricKey($0.key), value: String(format: "%.4g", $0.value)) }
                    .sorted { $0.label < $1.label }
            }
        }
        return []
    }

    func decodeSparkline(_ keys: [Key]) -> [Double] {
        for key in keys {
            if let values = try? decode([Double].self, forKey: key) {
                return values
            }
            if let values = try? decode([Int].self, forKey: key) {
                return values.map(Double.init)
            }
            if let points = try? decode([SparkPoint].self, forKey: key) {
                let prices = points.compactMap(\.price)
                if !prices.isEmpty {
                    return prices
                }
            }
        }
        return []
    }
}

private func prettifyMetricKey(_ key: String) -> String {
    key.replacingOccurrences(of: "_", with: " ").capitalized
}
