// BoardRowView.swift
// One coin on the board: score, families, and a single plain-English sentence.

import SwiftUI

struct BoardRowView: View {
    let row: BoardRow
    let presentation: RowPresentation
    let watching: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Text(presentation.why)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            FamilyChips(names: presentation.familyNames)
            if !presentation.proLines.isEmpty {
                proBlock
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(row.symbol)
                        .font(.headline)
                    if watching {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Watching")
                    }
                }
                Text(row.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            ScoreBadge(score: row.score)
        }
    }

    private var proBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(presentation.proLines, id: \.self) { line in
                Text(line)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
