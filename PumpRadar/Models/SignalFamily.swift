// SignalFamily.swift
// The eight reading families the board can explain.

import Foundation

struct SignalFamily: Equatable, Identifiable, Decodable {
    let id: String
    let name: String
    let explanation: String
    let weight: Double?

    init(id: String, name: String, explanation: String, weight: Double? = nil) {
        self.id = id
        self.name = name
        self.explanation = explanation
        self.weight = weight
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, explanation, description, summary, weight
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedID = container.decodeFlexString([.id]) ?? ""
        id = decodedID
        name = container.decodeFlexString([.name]) ?? SignalFamily.displayName(for: decodedID, in: [])
        explanation = container.decodeFlexString([.explanation, .description, .summary]) ?? ""
        weight = container.decodeFlexDouble([.weight])
    }

    static func displayName(for familyID: String, in families: [SignalFamily]) -> String {
        if let match = families.first(where: { $0.id == familyID }) {
            return match.name
        }
        if let builtin = builtins.first(where: { $0.id == familyID }) {
            return builtin.name
        }
        let cleaned = familyID.replacingOccurrences(of: "_", with: " ")
        return cleaned.isEmpty ? "Signal" : cleaned.capitalized
    }

    static let builtins: [SignalFamily] = [
        SignalFamily(
            id: "listings",
            name: "Listings",
            explanation: "A new exchange listing, or a credible listing notice, often brings a short burst of attention.",
            weight: 1.2
        ),
        SignalFamily(
            id: "etf_flows",
            name: "ETF flows",
            explanation: "Spot ETF creations and redemptions show whether funds were adding or removing coins that day.",
            weight: 1.1
        ),
        SignalFamily(
            id: "buzz",
            name: "X buzz",
            explanation: "Mentions on X are far above this coin's recent pace. Attention can fade as fast as it arrives.",
            weight: 1.0
        ),
        SignalFamily(
            id: "momentum",
            name: "Momentum",
            explanation: "Price is moving faster than this coin's own recent habit. Speed is not a direction you can bank on.",
            weight: 1.0
        ),
        SignalFamily(
            id: "sentiment",
            name: "Sentiment",
            explanation: "A broad mood reading such as the Fear & Greed index. It describes the room, not a single coin's future.",
            weight: 0.6
        ),
        SignalFamily(
            id: "funding",
            name: "Funding",
            explanation: "Perpetual funding is unusually high or low, which means leveraged traders are crowded to one side.",
            weight: 0.8
        ),
        SignalFamily(
            id: "order_book",
            name: "Order book",
            explanation: "Bids and asks near the price are lopsided. Books change quickly and can be pulled.",
            weight: 0.8
        ),
        SignalFamily(
            id: "divergence",
            name: "Divergence",
            explanation: "One exchange's price has pulled away from the others. The gap can close, widen, or be a bad print.",
            weight: 0.9
        )
    ]
}
