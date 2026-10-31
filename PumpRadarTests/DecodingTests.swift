// DecodingTests.swift
// The bundled sample files, plus camelCase, envelopes, and odd shapes.

import XCTest
@testable import PumpRadar

final class DecodingTests: XCTestCase {

    func testDemoBoardDecodesAndIsLabeledSample() throws {
        let board = try RadarJSON.decodeBoard(TestSupport.fixture("board"))
        XCTAssertTrue(board.sample)
        XCTAssertEqual(board.sampleLabel, Optional(Copy.sampleBanner))
        XCTAssertEqual(board.rows.count, 8)
        let first = try XCTUnwrap(board.rows.first)
        XCTAssertEqual(first.symbol, "PEPE")
        XCTAssertEqual(first.score, 81)
        XCTAssertEqual(first.familiesFired, ["listings", "buzz", "momentum"])
        XCTAssertEqual(first.sparkline.count, 10)
        XCTAssertNotNil(board.generatedAt)
        for row in board.rows {
            XCTAssertFalse(row.why.isEmpty)
            XCTAssertFalse(row.why.localizedCaseInsensitiveContains("guaranteed"))
            XCTAssertFalse(row.why.localizedCaseInsensitiveContains("buy now"))
        }
        let bitcoin = try XCTUnwrap(board.rows.first { $0.symbol == "BTC" })
        XCTAssertTrue(bitcoin.signals.contains { $0.family == "order_book" && $0.fired == false })
        XCTAssertFalse(bitcoin.firedFamilyIDs.contains("order_book"))
    }

    func testDemoEventsFamiliesSnapshotsAndTradable() throws {
        let events = try RadarJSON.decodeEvents(TestSupport.fixture("events"))
        XCTAssertTrue(events.sample)
        XCTAssertEqual(events.events.count, 6)
        let kinds = Set(events.events.map(\.kind))
        XCTAssertTrue(kinds.contains(.listing))
        XCTAssertTrue(kinds.contains(.etfFlow))
        XCTAssertTrue(kinds.contains(.buzz))
        XCTAssertTrue(kinds.contains(.orderBook))

        let families = try RadarJSON.decodeFamilies(TestSupport.fixture("families"))
        XCTAssertEqual(families.count, 8)
        let etf = try XCTUnwrap(families.first { $0.id == "etf_flows" })
        XCTAssertEqual(etf.name, "ETF flows")
        let buzz = try XCTUnwrap(families.first { $0.id == "buzz" })
        XCTAssertEqual(try XCTUnwrap(buzz.weight), 1.0)

        let snapshots = try RadarJSON.decodeSnapshots(TestSupport.fixture("snapshots"))
        XCTAssertEqual(snapshots.count, 2)
        let tia = try XCTUnwrap(snapshots.first { $0.symbol == "TIA" })
        XCTAssertEqual(tia.points.count, 6)

        let tradable = try RadarJSON.decodeTradable(TestSupport.fixture("tradable"))
        XCTAssertEqual(tradable.signals.map(\.symbol), ["PEPE", "WIF", "BTC"])
        XCTAssertTrue(tradable.signals.allSatisfy(\.tradable))
    }

    func testCamelCaseAndNumericScore() throws {
        let json = """
        {
          "generatedAt": "2026-10-31T15:00:00.250Z",
          "sample": false,
          "rows": [{
            "assetId": "sol",
            "symbol": "sol",
            "name": "Solana",
            "score": 70.6,
            "priceChange24hPct": -1.5,
            "why": "Momentum fired on its own.",
            "familiesFired": ["momentum"],
            "signals": [{
              "family": "momentum",
              "name": "Price momentum",
              "score": 70,
              "fired": true,
              "summary": "Faster than usual."
            }]
          }]
        }
        """.data(using: .utf8)!
        let board = try RadarJSON.decodeBoard(json)
        let row = try XCTUnwrap(board.rows.first)
        XCTAssertEqual(row.symbol, "SOL")
        XCTAssertEqual(row.score, 71)
        XCTAssertEqual(row.priceChange24hPct, -1.5)
        XCTAssertNotNil(board.generatedAt)
        XCTAssertEqual(row.firedFamilyIDs, ["momentum"])
    }

    func testEnvelopeAndTopLevelArray() throws {
        let envelope = """
        {"success": true, "data": {"sample": true, "rows": [
          {"symbol": "ADA", "name": "Cardano", "score": 10, "why": "Quiet."}
        ]}}
        """.data(using: .utf8)!
        let board = try RadarJSON.decodeBoard(envelope)
        XCTAssertTrue(board.sample)
        XCTAssertEqual(try XCTUnwrap(board.rows.first).symbol, "ADA")

        let array = """
        [{"symbol": "DOT", "name": "Polkadot", "score": "15", "why": "Quiet."}]
        """.data(using: .utf8)!
        let fromArray = try RadarJSON.decodeBoard(array)
        XCTAssertEqual(try XCTUnwrap(fromArray.rows.first).score, 15)
    }

    func testDictionarySignalsAndMetricMap() throws {
        let json = """
        {"rows": [{
          "symbol": "NEAR",
          "name": "NEAR",
          "score": 63,
          "signals": {
            "funding": {
              "score": 63,
              "fired": true,
              "summary": "Funding is crowded.",
              "metrics": {"funding_rate": "0.07%"}
            }
          }
        }]}
        """.data(using: .utf8)!
        let row = try XCTUnwrap(RadarJSON.decodeBoard(json).rows.first)
        let signal = try XCTUnwrap(row.signals.first)
        XCTAssertEqual(signal.family, "funding")
        XCTAssertEqual(signal.displayName, "Funding")
        XCTAssertEqual(row.firedFamilyIDs, ["funding"])
        XCTAssertEqual(try XCTUnwrap(signal.metrics.first).value, "0.07%")
    }

    func testUnknownEventKindAndAlternateKeys() throws {
        let json = """
        {"items": [{
          "type": "moonshot",
          "title": "A note",
          "description": "Not a known family.",
          "ticker": "abc",
          "time": "2026-10-31T15:00:00Z"
        }]}
        """.data(using: .utf8)!
        let page = try RadarJSON.decodeEvents(json)
        let event = try XCTUnwrap(page.events.first)
        XCTAssertEqual(event.kind, .other)
        XCTAssertEqual(event.symbol, "ABC")
        XCTAssertEqual(event.summary, "Not a known family.")
        XCTAssertNotNil(event.occurredAt)
        XCTAssertFalse(event.id.isEmpty)
    }

    func testSingleSnapshotObject() throws {
        let json = """
        {"symbol": "tia", "points": [{"price": 5.1}, {"price": 5.6}]}
        """.data(using: .utf8)!
        let series = try RadarJSON.decodeSnapshots(json)
        XCTAssertEqual(series.count, 1)
        let only = try XCTUnwrap(series.first)
        XCTAssertEqual(only.symbol, "TIA")
        XCTAssertEqual(only.points.compactMap(\.price), [5.1, 5.6])
    }

    func testPathsJoinBaseAndQuery() throws {
        let board = try XCTUnwrap(RadarPaths.url(base: "https://api.example.com/", path: "/radar/board"))
        XCTAssertEqual(board.absoluteString, "https://api.example.com/radar/board")
        let prefixed = try XCTUnwrap(RadarPaths.url(base: "https://api.example.com/v1", path: RadarRoute.events))
        XCTAssertEqual(prefixed.absoluteString, "https://api.example.com/v1/radar/events")
        let query = try XCTUnwrap(RadarPaths.url(
            base: "api.example.com",
            path: RadarRoute.snapshots,
            query: [URLQueryItem(name: "symbol", value: "BTC")]
        ))
        XCTAssertEqual(query.absoluteString, "https://api.example.com/radar/snapshots?symbol=BTC")
        XCTAssertNil(RadarPaths.url(base: "   ", path: RadarRoute.board))
    }

    func testDisclaimerIsAWatchlist() {
        XCTAssertTrue(Copy.disclaimer.contains("Not financial advice"))
        XCTAssertTrue(Copy.disclaimer.contains("does not buy, sell"))
        XCTAssertTrue(Copy.disclaimer.contains("not a promise of profit"))
        XCTAssertFalse(Copy.about.localizedCaseInsensitiveContains("guaranteed"))
        XCTAssertEqual(Copy.sampleBanner, "Sample data — not live market readings")
    }
}
