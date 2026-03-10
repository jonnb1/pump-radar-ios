// AlertsView.swift
// PumpRadar
//
// Displays pump detection alerts sorted by recency, with mark-as-read
// support and unread-count badge shown on the tab bar.

import SwiftUI

// MARK: - AlertsView

struct AlertsView: View {

    @StateObject private var viewModel = AlertsViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.alerts.isEmpty {
                    ProgressView("Loading alerts…")
                } else if viewModel.alerts.isEmpty {
                    emptyState
                } else {
                    alertList
                }
            }
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .refreshable { viewModel.loadAlerts() }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear { viewModel.loadAlerts() }
    }

    // MARK: - Subviews

    private var alertList: some View {
        List {
            ForEach(viewModel.alerts) { alert in
                AlertRowView(alert: alert)
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.markAsRead(alert) }
                    .swipeActions(edge: .leading) {
                        if !alert.isRead {
                            Button {
                                viewModel.markAsRead(alert)
                            } label: {
                                Label("Mark Read", systemImage: "checkmark.circle")
                            }
                            .tint(.blue)
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: viewModel.alerts.map(\.id))
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("No alerts yet")
                .font(.title3.bold())
            Text("Alerts appear here when suspicious activity is detected for coins in your watchlist.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.hasUnread {
                Button("Mark All Read") {
                    viewModel.markAllAsRead()
                }
                .font(.subheadline)
            }
        }
    }
}

// MARK: - AlertRowView

struct AlertRowView: View {
    let alert: PumpAlert

    var body: some View {
        HStack(spacing: 12) {
            // Severity icon
            Image(systemName: alert.severity.iconName)
                .foregroundColor(severityColor)
                .font(.title3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.coinSymbol)
                        .font(.headline)
                        .foregroundColor(alert.isRead ? .secondary : .primary)
                    Spacer()
                    Text(alert.relativeTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(alert.isRead ? .secondary : .primary)
                    .lineLimit(2)
                scoreDeltaBadge
            }
        }
        .padding(.vertical, 4)
        .opacity(alert.isRead ? 0.7 : 1)
    }

    private var scoreDeltaBadge: some View {
        HStack(spacing: 4) {
            Text("Score")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(alert.previousScore)")
                .font(.caption2.bold())
            Image(systemName: "arrow.right")
                .font(.caption2)
            Text("\(alert.currentScore)")
                .font(.caption2.bold())
                .foregroundColor(Color.pumpScoreColor(score: alert.currentScore))
        }
    }

    private var severityColor: Color {
        switch alert.severity {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    AlertsView()
}

#Preview("Alert Row") {
    List {
        AlertRowView(alert: .preview)
        AlertRowView(alert: .previewRead)
    }
    .listStyle(.insetGrouped)
}
#endif
