// ModelTests.swift
// PumpRadarTests
//
// Unit tests for the core data models: Coin, PumpAlert, User.

import XCTest
@testable import PumpRadar

// MARK: - CoinTests

final class CoinTests: XCTestCase {

    // MARK: - ActivityStage

    func testComputedStageNormal() {
        let coin = makeCoin(score: 15)
        XCTAssertEqual(coin.computedStage, .normal)
    }

    func testComputedStageEarlyAtLowerBound() {
        let coin = makeCoin(score: Constants.Scoring.earlyThreshold)
        XCTAssertEqual(coin.computedStage, .early)
    }

    func testComputedStageActiveAtLowerBound() {
        let coin = makeCoin(score: Constants.Scoring.activeThreshold)
        XCTAssertEqual(coin.computedStage, .active)
    }

    func testComputedStageHighRiskAtLowerBound() {
        let coin = makeCoin(score: Constants.Scoring.highRiskThreshold)
        XCTAssertEqual(coin.computedStage, .highRisk)
    }

    func testComputedStageHighRiskAtMax() {
        let coin = makeCoin(score: 100)
        XCTAssertEqual(coin.computedStage, .highRisk)
    }

    // MARK: - Formatted Price

    func testFormattedPriceLargeValue() {
        let coin = makeCoin(price: 1234.56)
        XCTAssertEqual(coin.formattedPrice, "$1234.56")
    }

    func testFormattedPriceSmallValue() {
        let coin = makeCoin(price: 0.000001234)
        XCTAssertTrue(coin.formattedPrice.hasPrefix("$0.000001"))
    }

    // MARK: - Formatted Volume

    func testFormattedVolumeMillions() {
        let coin = makeCoin(volume: 2_500_000)
        XCTAssertEqual(coin.formattedVolume, "2.50M")
    }

    func testFormattedVolumeThousands() {
        let coin = makeCoin(volume: 4_500)
        XCTAssertEqual(coin.formattedVolume, "4.50K")
    }

    func testFormattedVolumeBillions() {
        let coin = makeCoin(volume: 1_200_000_000)
        XCTAssertEqual(coin.formattedVolume, "1.20B")
    }

    // MARK: - Equatable / Hashable

    func testEqualCoinsShareSameId() {
        let a = makeCoin(id: "test-id")
        let b = makeCoin(id: "test-id")
        XCTAssertEqual(a, b)
    }

    func testDifferentIdsAreNotEqual() {
        let a = makeCoin(id: "id-a")
        let b = makeCoin(id: "id-b")
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Codable

    func testCoinRoundTripsViaJSON() throws {
        let original = makeCoin()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Coin.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.symbol, original.symbol)
        XCTAssertEqual(decoded.score, original.score)
    }

    // MARK: - Helpers

    private func makeCoin(
        id: String = "test-coin",
        score: Int = 50,
        price: Double = 0.001,
        volume: Double = 1_000_000
    ) -> Coin {
        Coin(
            id: id,
            symbol: "TEST",
            name: "Test Coin",
            price: price,
            priceChangePercent: 5.0,
            volume: volume,
            volumeChangePercent: 20.0,
            score: score,
            stage: .normal,
            signalChange: 2.0,
            reasonsFlagged: [],
            signalHistory: [],
            isFavorite: false
        )
    }
}

// MARK: - ActivityStageTests

final class ActivityStageTests: XCTestCase {

    func testAllCasesHaveNonEmptyDisplayName() {
        ActivityStage.allCases.forEach {
            XCTAssertFalse($0.displayName.isEmpty)
        }
    }

    func testAllCasesHaveNonEmptyIconName() {
        ActivityStage.allCases.forEach {
            XCTAssertFalse($0.iconName.isEmpty)
        }
    }

    func testRawValueRoundTrip() throws {
        for stage in ActivityStage.allCases {
            let data = try JSONEncoder().encode(stage)
            let decoded = try JSONDecoder().decode(ActivityStage.self, from: data)
            XCTAssertEqual(decoded, stage)
        }
    }
}

// MARK: - PumpAlertTests

final class PumpAlertTests: XCTestCase {

    func testScoreDeltaIsCalculatedCorrectly() {
        let alert = makeAlert(previousScore: 30, currentScore: 72)
        XCTAssertEqual(alert.scoreDelta, 42)
    }

    func testScoreDeltaNegativeWhenScoreDrops() {
        let alert = makeAlert(previousScore: 80, currentScore: 50)
        XCTAssertEqual(alert.scoreDelta, -30)
    }

    func testRelativeTimestampIsNonEmpty() {
        let alert = makeAlert()
        XCTAssertFalse(alert.relativeTimestamp.isEmpty)
    }

    func testCodableRoundTrip() throws {
        let original = makeAlert()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PumpAlert.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.currentScore, original.currentScore)
    }

    // MARK: - Helpers

    private func makeAlert(previousScore: Int = 45, currentScore: Int = 72) -> PumpAlert {
        PumpAlert(
            id: "test-alert",
            coinId: "pepe",
            coinSymbol: "PEPE",
            coinName: "Pepe",
            previousScore: previousScore,
            currentScore: currentScore,
            severity: .high,
            message: "Test alert message",
            createdAt: Date().addingTimeInterval(-300),
            isRead: false
        )
    }
}

// MARK: - UserTests

final class UserTests: XCTestCase {

    func testUserCodableRoundTrip() throws {
        let original = User(id: "u1", email: "a@b.com", username: "user1", createdAt: Date(timeIntervalSince1970: 0))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(User.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.email, original.email)
        XCTAssertEqual(decoded.username, original.username)
    }
}
