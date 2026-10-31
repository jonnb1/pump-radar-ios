// ViewModelTests.swift
// Board ranking, demo mode, scorecards, events, and detail sparklines.

import XCTest
@testable import PumpRadar

@MainActor
final class ViewModelTests: XCTestCase {

    func testRankThenScoreThenSymbol() async {
        let client = FakeRadarClient(board: RadarBoard(
            generatedAt: nil,
            sample: false,
            sampleLabel: nil,
            marketNote: nil,
            rows: [
                TestSupport.row(symbol: "BBB", score: 90, rank: 2, why: "Second."),
                TestSupport.row(symbol: "CCC", score: 10, rank: 1, why: "First."),
                TestSupport.row(symbol: "DDD", score: 90, why: "Same score, later symbol."),
                TestSupport.row(symbol: "AAA", score: 90, why: "Same score, earlier symbol.")
            ]
        ))
        let viewModel = await makeBoard(client: client)
        await viewModel.load()
        XCTAssertEqual(viewModel.rows.map(\.symbol), ["CCC", "BBB", "AAA", "DDD"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSearchAndWatchlistFilter() async {
        let client = FakeRadarClient(board: RadarBoard(
            generatedAt: nil,
            sample: false,
            sampleLabel: nil,
            marketNote: "Note",
            rows: [
                TestSupport.row(symbol: "PEPE", score: 80, why: "Listing cluster."),
                TestSupport.row(symbol: "LINK", score: 20, why: "Quiet baseline.")
            ]
        ))
        let defaults = try? TestSupport.defaults()
        let watchlist = WatchlistStore(defaults: defaults ?? .standard)
        watchlist.toggle("LINK")
        let viewModel = BoardViewModel(
            settings: AppSettings(defaults: defaults ?? .standard),
            watchlist: watchlist,
            client: client,
            alerts: RecordingScheduler()
        )
        await viewModel.load()
        viewModel.searchText = "quiet"
        XCTAssertEqual(viewModel.visibleRows.map(\.symbol), ["LINK"])
        viewModel.searchText = ""
        viewModel.watchlistOnly = true
        XCTAssertEqual(viewModel.visibleRows.map(\.symbol), ["LINK"])
    }

    func testBlankWhyIsComposedAndProLinesStayHiddenInSimpleMode() async throws {
        let reading = SignalReading(
            family: "buzz",
            name: "X mentions",
            score: 80,
            fired: true,
            summary: "Mentions jumped."
        )
        let client = FakeRadarClient(board: RadarBoard(
            generatedAt: nil,
            sample: true,
            sampleLabel: Copy.sampleBanner,
            marketNote: nil,
            rows: [TestSupport.row(symbol: "WIF", score: 70, families: ["buzz"], signals: [reading], tradable: true)]
        ))
        let viewModel = await makeBoard(client: client)
        await viewModel.load()
        let row = try XCTUnwrap(viewModel.rows.first)
        let simple = RowPresenter.make(row: row, families: viewModel.families, pro: false)
        XCTAssertTrue(simple.why.contains("X buzz"))
        XCTAssertTrue(simple.proLines.isEmpty)
        XCTAssertEqual(simple.familyNames, ["X buzz"])
        let pro = RowPresenter.make(row: row, families: viewModel.families, pro: true)
        XCTAssertTrue(pro.proLines.contains("Passes the data filter"))
        XCTAssertTrue(pro.proLines.contains { $0.contains("X mentions 80") })
    }

    func testScorecardCountsQuietFamilies() {
        let row = TestSupport.row(symbol: "PEPE", score: 81, families: ["listings", "buzz", "momentum"])
        let card = ScorecardBuilder.make(row: row, families: SignalFamily.builtins)
        XCTAssertEqual(card.headline, "3 of 8 signal families fired")
        XCTAssertEqual(card.firedNames, ["Listings", "X buzz", "Momentum"])
        XCTAssertTrue(card.quietNames.contains("ETF flows"))
        XCTAssertTrue(card.quietNames.contains("Funding"))
        XCTAssertTrue(card.detail.contains("Quiet:"))
    }

    func testEmptyFamiliesStayHonest() {
        let card = ScorecardBuilder.make(row: TestSupport.row(symbol: "LINK", score: 22), families: [])
        XCTAssertEqual(card.headline, "0 of 8 signal families fired")
        XCTAssertEqual(card.detail, "Nothing looks unusual against recent baselines.")
        let sentence = PlainEnglish.why(for: TestSupport.row(symbol: "LINK", score: 22), families: [])
        XCTAssertTrue(sentence.contains("No signal family looks unusual"))
    }

    func testTradableEndpointUpgradesTheFlag() async throws {
        let client = FakeRadarClient(board: RadarBoard(
            generatedAt: nil,
            sample: false,
            sampleLabel: nil,
            marketNote: nil,
            rows: [TestSupport.row(symbol: "WIF", score: 74, why: "Buzz.", tradable: false)]
        ))
        client.tradable = .success(TradablePage(
            generatedAt: nil,
            sample: false,
            signals: [TradableSignal(symbol: "wif", score: 74, tradable: true, why: "Filter passed.")]
        ))
        let viewModel = await makeBoard(client: client)
        await viewModel.load()
        XCTAssertEqual(try XCTUnwrap(viewModel.rows.first).tradable, true)
    }

    func testLiveModeWithoutURLSetsAnErrorAndKeepsTheBoard() async throws {
        let defaults = try TestSupport.defaults()
        let settings = AppSettings(defaults: defaults)
        settings.demoMode = false
        settings.apiBaseURL = "  "
        let viewModel = BoardViewModel(
            settings: settings,
            watchlist: WatchlistStore(defaults: defaults),
            alerts: RecordingScheduler()
        )
        await viewModel.load()
        XCTAssertTrue(viewModel.rows.isEmpty)
        XCTAssertTrue(viewModel.errorMessage?.contains("Demo mode") == true)
    }

    func testFailedReloadKeepsPreviousRows() async {
        let client = FakeRadarClient(board: RadarBoard(
            generatedAt: nil,
            sample: false,
            sampleLabel: nil,
            marketNote: nil,
            rows: [TestSupport.row(symbol: "PEPE", score: 80, why: "Still here.")]
        ))
        let viewModel = await makeBoard(client: client)
        await viewModel.load()
        client.board = .failure(RadarClientError.http(500))
        await viewModel.load()
        XCTAssertEqual(viewModel.rows.map(\.symbol), ["PEPE"])
        XCTAssertEqual(viewModel.errorMessage, RadarClientError.http(500).errorDescription)
    }

    func testWatchAlertsFireOnceAndSkipLowScores() async throws {
        let scheduler = RecordingScheduler()
        let defaults = try TestSupport.defaults()
        let settings = AppSettings(defaults: defaults)
        settings.alertsEnabled = true
        settings.alertThreshold = 70
        let watchlist = WatchlistStore(defaults: defaults)
        watchlist.toggle("pepe")
        let client = FakeRadarClient(board: RadarBoard(
            generatedAt: nil,
            sample: false,
            sampleLabel: nil,
            marketNote: nil,
            rows: [
                TestSupport.row(symbol: "PEPE", score: 81, why: "Cluster.", families: ["listings", "buzz"]),
                TestSupport.row(symbol: "LINK", score: 22, why: "Quiet.")
            ]
        ))
        let viewModel = BoardViewModel(
            settings: settings,
            watchlist: watchlist,
            client: client,
            alerts: scheduler
        )
        await viewModel.load()
        await viewModel.load()
        XCTAssertEqual(scheduler.messages.count, 1)
        let message = try XCTUnwrap(scheduler.messages.first)
        XCTAssertEqual(message.title, "PEPE is on the board")
        XCTAssertTrue(message.body.contains("Not financial advice"))
        XCTAssertTrue(message.body.contains("Listings and X buzz are active"))
        XCTAssertFalse(message.body.contains("LINK"))
    }

    func testDemoModeLoadsBundledSampleAndMergesWIF() async throws {
        let defaults = try TestSupport.defaults()
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.demoMode)
        let viewModel = BoardViewModel(
            settings: settings,
            watchlist: WatchlistStore(defaults: defaults),
            alerts: RecordingScheduler()
        )
        await viewModel.load()
        XCTAssertTrue(viewModel.isSample)
        XCTAssertEqual(viewModel.sampleLabel, Optional(Copy.sampleBanner))
        XCTAssertEqual(try XCTUnwrap(viewModel.rows.first).symbol, "PEPE")
        XCTAssertEqual(viewModel.families.count, 8)
        let wif = try XCTUnwrap(viewModel.rows.first { $0.symbol == "WIF" })
        XCTAssertTrue(wif.tradable)
        let link = try XCTUnwrap(viewModel.rows.first { $0.symbol == "LINK" })
        XCTAssertFalse(link.tradable)
        XCTAssertTrue(viewModel.marketNote?.contains("Sample data") == true)
    }

    func testDetailFillsSparklineFromSnapshotsAndFiltersEvents() async throws {
        let row = TestSupport.row(symbol: "TIA", score: 69, why: "Book and gap.", families: ["order_book"])
        let client = FakeRadarClient(board: RadarBoard(
            generatedAt: nil,
            sample: true,
            sampleLabel: nil,
            marketNote: nil,
            rows: [row]
        ))
        client.snapshots = [
            SnapshotSeries(symbol: "TIA", points: [
                SnapshotPoint(timestamp: nil, price: 5.1, score: nil),
                SnapshotPoint(timestamp: nil, price: 5.6, score: nil)
            ])
        ]
        client.events = .success(RadarEventsPage(
            sample: true,
            sampleLabel: nil,
            events: [
                RadarEvent(id: "1", kind: .orderBook, title: "TIA book", summary: "Lopsided.", symbol: "TIA"),
                RadarEvent(id: "2", kind: .listing, title: "PEPE listing", summary: "Listed.", symbol: "PEPE")
            ]
        ))
        let defaults = try TestSupport.defaults()
        let viewModel = CoinDetailViewModel(
            row: row,
            settings: AppSettings(defaults: defaults),
            watchlist: WatchlistStore(defaults: defaults),
            client: client
        )
        XCTAssertTrue(viewModel.sparkline.isEmpty)
        await viewModel.load()
        XCTAssertEqual(viewModel.sparkline, [5.1, 5.6])
        XCTAssertEqual(viewModel.events.compactMap(\.symbol), ["TIA"])
        let card = viewModel.scorecard
        XCTAssertEqual(card.firedNames, ["Order book"])
    }

    func testEventsFilterAndSort() async throws {
        let older = RadarEvent(
            id: "old",
            kind: .listing,
            title: "Old listing",
            summary: "Earlier.",
            symbol: "AAA",
            occurredAt: Date(timeIntervalSince1970: 10)
        )
        let newer = RadarEvent(
            id: "new",
            kind: .buzz,
            title: "New buzz",
            summary: "Later.",
            symbol: "BBB",
            occurredAt: Date(timeIntervalSince1970: 50)
        )
        let client = FakeRadarClient(board: RadarBoard(
            generatedAt: nil, sample: false, sampleLabel: nil, marketNote: nil, rows: []
        ))
        client.events = .success(RadarEventsPage(sample: true, sampleLabel: Copy.sampleBanner, events: [older, newer]))
        let defaults = try TestSupport.defaults()
        let viewModel = EventsViewModel(settings: AppSettings(defaults: defaults), client: client)
        await viewModel.load()
        XCTAssertEqual(viewModel.visibleEvents.map(\.id), ["new", "old"])
        XCTAssertTrue(viewModel.isSample)
        viewModel.filter = .listings
        XCTAssertEqual(viewModel.visibleEvents.map(\.id), ["old"])
        viewModel.filter = .etfFlows
        XCTAssertTrue(viewModel.visibleEvents.isEmpty)
    }

    func testSettingsAndWatchlistPersist() throws {
        let defaults = try TestSupport.defaults()
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.demoMode)
        XCTAssertFalse(settings.proMode)
        XCTAssertEqual(settings.alertThreshold, 70)
        settings.demoMode = false
        settings.apiBaseURL = "https://radar.example"
        settings.proMode = true
        settings.alertThreshold = 85
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertFalse(reloaded.demoMode)
        XCTAssertEqual(reloaded.apiBaseURL, "https://radar.example")
        XCTAssertTrue(reloaded.proMode)
        XCTAssertEqual(reloaded.alertThreshold, 85)

        let watchlist = WatchlistStore(defaults: defaults)
        watchlist.toggle("pepe")
        watchlist.toggle("btc")
        watchlist.toggle("pepe")
        let stored = WatchlistStore(defaults: defaults)
        XCTAssertTrue(stored.contains("BTC"))
        XCTAssertFalse(stored.contains("PEPE"))
    }

    func testPlainEnglishList() {
        XCTAssertEqual(PlainEnglish.list([]), "")
        XCTAssertEqual(PlainEnglish.list(["Listings"]), "Listings")
        XCTAssertEqual(PlainEnglish.list(["Listings", "X buzz"]), "Listings and X buzz")
        XCTAssertEqual(
            PlainEnglish.list(["Listings", "X buzz", "Momentum"]),
            "Listings, X buzz, and Momentum"
        )
    }

    private func makeBoard(client: FakeRadarClient) async -> BoardViewModel {
        let defaults = try? TestSupport.defaults()
        let resolved = defaults ?? .standard
        return BoardViewModel(
            settings: AppSettings(defaults: resolved),
            watchlist: WatchlistStore(defaults: resolved),
            client: client,
            alerts: RecordingScheduler()
        )
    }
}
