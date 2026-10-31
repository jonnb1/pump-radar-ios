// EventsView.swift
// Listings, ETF flow days, and buzz spikes.

import SwiftUI

struct EventsView: View {
    @ObservedObject var viewModel: EventsViewModel
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.events.isEmpty && viewModel.errorMessage == nil {
                    ProgressView("Loading events")
                } else {
                    eventList
                }
            }
            .navigationTitle("Events")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .onChange(of: settings.demoMode) { _, _ in
                Task { await viewModel.load() }
            }
            .onChange(of: settings.apiBaseURL) { _, _ in
                Task { await viewModel.load() }
            }
        }
    }

    private var eventList: some View {
        List {
            if viewModel.isSample {
                Section {
                    SampleBanner(text: viewModel.sampleLabel ?? Copy.sampleBanner)
                }
            }
            Section {
                Picker("Kind", selection: $viewModel.filter) {
                    ForEach(EventFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
            if let error = viewModel.errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Try again") {
                            Task { await viewModel.load() }
                        }
                        if !settings.demoMode {
                            Button("Use sample data") {
                                settings.demoMode = true
                            }
                        }
                    }
                }
            }
            Section {
                if viewModel.visibleEvents.isEmpty {
                    Text("No events in this filter.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.visibleEvents) { event in
                        eventRow(event)
                    }
                }
            } footer: {
                DisclaimerFooter()
            }
        }
        .listStyle(.insetGrouped)
    }

    private func eventRow(_ event: RadarEvent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(event.kind.title, systemImage: event.kind.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let symbol = event.symbol {
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                }
            }
            Text(event.title)
                .font(.headline)
            Text(event.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let date = event.occurredAt {
                Text(Formatting.timestamp(date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
