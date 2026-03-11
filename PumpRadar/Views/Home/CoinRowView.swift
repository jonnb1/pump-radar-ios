// CoinRowView.swift
// PumpRadar
//
// A single row in the home-screen coin list, showing the pump score,
// activity stage badge, price, and key change metrics.

import SwiftUI

// MARK: - CoinRowView

struct CoinRowView: View {
    let coin: Coin
    let onWatchlistToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Score circle
            scoreCircle

            // Coin info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(coin.symbol)
                        .font(.headline)
                    stageBadge(stage: coin.computedStage)
                    Spacer()
                    signalChangeLabel
                }
                Text(coin.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Text(coin.formattedPrice)
                        .font(.subheadline)
                    priceChangeBadge
                    Spacer()
                    volumeLabel
                }
            }

            // Watchlist button
            watchlistButton
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // MARK: - Subviews

    private var scoreCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.pumpScoreColor(score: coin.score).opacity(0.3), lineWidth: 4)
                .frame(width: 48, height: 48)
            Circle()
                .trim(from: 0, to: CGFloat(coin.score) / 100)
                .stroke(Color.pumpScoreColor(score: coin.score), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(-90))
            Text("\(coin.score)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.pumpScoreColor(score: coin.score))
        }
        .animation(.easeInOut(duration: Constants.UI.animationDuration), value: coin.score)
    }

    private func stageBadge(stage: ActivityStage) -> some View {
        Text(stage.displayName)
            .font(.caption2.bold())
            .foregroundColor(stageColor(stage))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(stageColor(stage).opacity(0.15))
            .cornerRadius(4)
    }

    private var signalChangeLabel: some View {
        HStack(spacing: 2) {
            Image(systemName: coin.signalChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
            Text(coin.signalChange.formattedPercentage)
                .font(.caption2.bold())
        }
        .foregroundColor(Color.changeColor(value: coin.signalChange))
    }

    private var priceChangeBadge: some View {
        Text(coin.priceChangePercent.formattedPercentage)
            .font(.caption2)
            .foregroundColor(Color.changeColor(value: coin.priceChangePercent))
    }

    private var volumeLabel: some View {
        HStack(spacing: 2) {
            Image(systemName: "chart.bar.fill")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(coin.formattedVolume)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var watchlistButton: some View {
        Button(action: onWatchlistToggle) {
            Image(systemName: coin.isFavorite ? "star.fill" : "star")
                .foregroundColor(coin.isFavorite ? .yellow : .gray)
                .font(.system(size: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func stageColor(_ stage: ActivityStage) -> Color {
        switch stage {
        case .normal: return .green
        case .early: return .blue
        case .active: return .orange
        case .highRisk: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    List {
        CoinRowView(coin: .preview) {}
        CoinRowView(coin: .previewWatchlisted) {}
    }
    .listStyle(.insetGrouped)
}
#endif
