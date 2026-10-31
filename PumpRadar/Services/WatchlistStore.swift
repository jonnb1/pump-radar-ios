// WatchlistStore.swift
// Symbols the person is watching. Stored only on this iPhone.

import Combine
import Foundation

@MainActor
final class WatchlistStore: ObservableObject {
    @Published private(set) var symbols: Set<String>
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.stringArray(forKey: StorageKey.watchlistSymbols) ?? []
        symbols = Set(saved.map { $0.uppercased() })
    }

    func contains(_ symbol: String) -> Bool {
        symbols.contains(symbol.uppercased())
    }

    func toggle(_ symbol: String) {
        let key = symbol.uppercased()
        if symbols.contains(key) {
            symbols.remove(key)
        } else {
            symbols.insert(key)
        }
        defaults.set(symbols.sorted(), forKey: StorageKey.watchlistSymbols)
    }
}
