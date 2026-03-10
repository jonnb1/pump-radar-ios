// CoinDetailView.swift
// PumpRadar
//
// Detailed view for a single coin: pump score, activity stage, reasons
// flagged, signal history chart, and price/volume metrics.

import SwiftUI

// MARK: - CoinDetailView

struct CoinDetailView: View {

    @StateObject var viewModel: CoinDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                scoreHeader
                metricsGrid
                reasonsSection
                signalHistorySection
            }
            .padding()
        }
        .navigationTitle(viewModel.coin.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .refreshable { viewModel.refresh() }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var scoreHeader: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.coin.name)
                        .font(.title2.bold())
                    Text(viewModel.coin.symbol)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Large score ring
                largeScoreRing(score: viewModel.coin.score)
            }

            // Stage banner
            HStack {
                Image(systemName: viewModel.coin.computedStage.iconName)
                Text(viewModel.coin.computedStage.displayName)
                    .fontWeight(.semibold)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Signal change")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.coin.signalChange.formattedPercentage)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.changeColor(value: viewModel.coin.signalChange))
                }
            }
            .foregroundColor(stageColor(viewModel.coin.computedStage))
            .padding()
            .background(stageColor(viewModel.coin.computedStage).opacity(0.1))
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .cardStyle()
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Price",
                value: viewModel.coin.formattedPrice,
                change: viewModel.coin.priceChangePercent,
                icon: "dollarsign.circle"
            )
            MetricCard(
                title: "24h Volume",
                value: viewModel.coin.formattedVolume,
                change: viewModel.coin.volumeChangePercent,
                icon: "chart.bar"
            )
        }
    }

    @ViewBuilder
    private var reasonsSection: some View {
        if !viewModel.coin.reasonsFlagged.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Why Flagged")
                    .font(.headline)
                ForEach(viewModel.coin.reasonsFlagged, id: \.self) { reason in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(reason)
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    @ViewBuilder
    private var signalHistorySection: some View {
        if !viewModel.coin.signalHistory.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Signal History")
                    .font(.headline)
                SignalHistoryChart(history: viewModel.coin.signalHistory)
                    .frame(height: 120)
            }
            .cardStyle()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                viewModel.toggleWatchlist()
            } label: {
                if viewModel.isAddingToWatchlist {
                    ProgressView()
                } else {
                    Image(systemName: viewModel.coin.isFavorite ? "star.fill" : "star")
                        .foregroundColor(viewModel.coin.isFavorite ? .yellow : .gray)
                }
            }
        }
    }

    // MARK: - Helpers

    private func largeScoreRing(score: Int) -> some View {
        ZStack {
            Circle()
                .stroke(Color.pumpScoreColor(score: score).opacity(0.2), lineWidth: 8)
                .frame(width: 72, height: 72)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(Color.pumpScoreColor(score: score), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: score)
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.title3.bold())
                    .foregroundColor(Color.pumpScoreColor(score: score))
                Text("/ 100")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func stageColor(_ stage: ActivityStage) -> Color {
        switch stage {
        case .normal: return .green
        case .early: return .blue
        case .active: return .orange
        case .highRisk: return .red
        }
    }
}

// MARK: - MetricCard

struct MetricCard: View {
    let title: String
    let value: String
    let change: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.headline)
            HStack(spacing: 2) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text(change.formattedPercentage)
                    .font(.caption2)
            }
            .foregroundColor(Color.changeColor(value: change))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - SignalHistoryChart

/// A simple bar chart showing the signal score over time.
struct SignalHistoryChart: View {
    let history: [SignalHistoryEntry]

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(history) { entry in
                    let barHeight = geo.size.height * CGFloat(entry.score) / 100
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.pumpScoreColor(score: entry.score))
                        .frame(maxWidth: .infinity, minHeight: 4, maxHeight: barHeight)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationView {
        CoinDetailView(viewModel: CoinDetailViewModel(coin: .preview))
    }
}
#endif
