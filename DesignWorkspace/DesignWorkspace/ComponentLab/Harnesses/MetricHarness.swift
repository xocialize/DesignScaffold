//
//  MetricHarness.swift
//  DesignWorkspace — Component Lab
//

import DesignScaffold
import DesignScaffoldMetrics
import DesignScaffoldProbe
import SwiftUI

/// The metric tile, including the two cases a screenshot of happy values would not show:
/// a number too long for its tile, and a value carrying a verdict.
struct MetricHarness: View {
    @State private var wide = false

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            Text("The grid wraps at Tokens.Layout.metricTileMinWidth (140) — the width at which two tiles fit an inspector. Narrow the pane and it goes to one column rather than squeezing.")
                .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            Button(wide ? "→ inspector width (340)" : "→ wide (700)") { wide.toggle() }
                .hitTestProbe("width-toggle")

            MetricGrid {
                MetricTile("0.31", label: "Time to first audio", unit: "s").carded()
                MetricTile("2.41", label: "Resident", unit: "GB", caption: "1 of 1 resident").carded()
                MetricTile("24", label: "Sample rate", unit: "kHz").carded()
                // A value carrying a verdict — the one thing the host owns.
                MetricTile("−0.2", label: "Peak", unit: "dBFS",
                           caption: "clipped", emphasis: Tokens.Color.failure).carded()
                // ⚠️ Deliberately absurd: shrink, never truncate. "1,284,…" would read as a
                // number and the reader could not tell it was not one.
                MetricTile("1,284,905,772", label: "Samples").carded()
            }
            .frame(width: wide ? 700 : 340)
            .hitTestProbe("grid")

            Text("Inline theme — no card, for chrome that already has a surface")
                .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
            HStack(spacing: Tokens.Space.l) {
                MetricTile("2.41", label: "Resident · VoxCPM2", unit: "GB").theme(.inline)
                MetricTile("28", label: "Takes kept").theme(.inline)
            }
            .frame(width: 340).padding(Tokens.Space.s).cardSurface()

            Spacer(minLength: 0)
        }
    }
}
