// Constants.swift
// Shared copy and storage keys. The app is a watchlist: it never trades.

import Foundation

enum Copy {
    static let disclaimer = """
    Not financial advice. Pump Radar is a watchlist. It explains unusual market \
    readings in plain English. It does not buy, sell, or connect to a wallet, \
    and a high score is not a promise of profit.
    """

    static let sampleBanner = "Sample data — not live market readings"

    static let about = """
    Pump Radar is a one-screen signal board. Each row is a coin, a score, the \
    signal families that look unusual, and a sentence that says why. You can \
    watch a coin on this iPhone. Nothing in the app places an order.
    """

    static let dataFilterNote = """
    The server marked this coin as tradable, meaning it cleared a liquidity and \
    data-quality filter. That is not a recommendation to trade.
    """
}

enum StorageKey {
    static let demoMode = "demoMode"
    static let apiBaseURL = "apiBaseURL"
    static let proMode = "proMode"
    static let alertsEnabled = "alertsEnabled"
    static let alertThreshold = "alertThreshold"
    static let watchlistSymbols = "watchlistSymbols"
}

enum RadarRoute {
    static let board = "radar/board"
    static let events = "radar/events"
    static let families = "radar/families"
    static let snapshots = "radar/snapshots"
    static let tradable = "signals/tradable"
}
