// EventsViewModel.swift
// Listings, ETF flow days, and buzz spikes, newest first.

import Combine
import Foundation

@MainActor
final class EventsViewModel: ObservableObject {
    @Published private(set) var events: [RadarEvent] = []
    @Published private(set) var isSample = false
    @Published private(set) var sampleLabel: String?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var filter: EventFilter = .all

    let settings: AppSettings
    private let clientOverride: RadarClient?

    init(settings: AppSettings, client: RadarClient? = nil) {
        self.settings = settings
        self.clientOverride = client
    }

    var visibleEvents: [RadarEvent] {
        events
            .filter { filter.matches($0.kind) }
            .sorted { lhs, rhs in
                (lhs.occurredAt ?? .distantPast) > (rhs.occurredAt ?? .distantPast)
            }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let client = clientOverride ?? RadarClientFactory.make(settings: settings)
        do {
            let page = try await client.fetchEvents()
            events = page.events
            isSample = page.sample
            sampleLabel = page.sampleLabel
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
