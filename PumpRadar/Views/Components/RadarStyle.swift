// RadarStyle.swift
// Shared calm pieces. Scores use a quiet tint, not a profit color.

import SwiftUI

enum RadarStyle {
    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case ..<35:
            return .secondary
        case 35..<65:
            return .accentColor
        default:
            return .orange
        }
    }
}

struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.title3.weight(.semibold).monospacedDigit())
            .foregroundStyle(RadarStyle.scoreColor(score))
            .frame(minWidth: 36, alignment: .trailing)
            .accessibilityLabel("Score \(score) out of 100")
    }
}

struct DisclaimerFooter: View {
    var body: some View {
        Text(Copy.disclaimer)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("disclaimer")
    }
}

struct SampleBanner: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "doc.text")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .accessibilityIdentifier("sample-banner")
    }
}

struct FamilyChips: View {
    let names: [String]

    var body: some View {
        if names.isEmpty {
            Text("No family fired")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(names, id: \.self) { name in
                        Text(name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12), in: Capsule())
                    }
                }
            }
        }
    }
}
