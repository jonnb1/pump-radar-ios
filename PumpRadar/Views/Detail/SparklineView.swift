// SparklineView.swift
// A plain price path. It does not mark entries, exits, or targets.

import SwiftUI

struct SparklineView: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            sparkPath(in: geo.size)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
        }
        .frame(height: 72)
        .accessibilityLabel("Recent price path")
    }

    private func sparkPath(in size: CGSize) -> Path {
        var path = Path()
        guard values.count >= 2 else {
            return path
        }
        let low = values.min() ?? 0
        let high = values.max() ?? 0
        let span = max(high - low, 0.0000001)
        let lastIndex = CGFloat(values.count - 1)
        for (index, value) in values.enumerated() {
            let x = size.width * CGFloat(index) / lastIndex
            let y = size.height * (1 - CGFloat((value - low) / span))
            let point = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}
