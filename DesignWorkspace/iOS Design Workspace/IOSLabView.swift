//
//  IOSLabView.swift
//  iOS Design Workspace
//

import Combine
import DesignScaffold
import DesignScaffoldChips
import DesignScaffoldControls
import DesignScaffoldMetrics
import DesignScaffoldStageStepper
import DesignScaffoldStatus
import DesignScaffoldWaveform
import SwiftUI

struct IOSLabView: View {
    @State private var showBands = true
    @State private var measured: [String: CGFloat] = [:]

    @State private var temperature = 0.8
    @State private var steps = 20
    @State private var chip = "b"
    @State private var elapsed: TimeInterval = 0

    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let chips = ["a", "b", "c", "d", "e"].map(Chip.init)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                    verdict
                    tierTwo
                    tierOne
                }
                .padding(Tokens.Space.m)
            }
            .background(Tokens.Color.surface)
            .navigationTitle("DesignScaffold · iOS")
            .toolbar {
                Toggle("44pt", isOn: $showBands).toggleStyle(.switch)
            }
        }
        .onReceive(tick) { _ in elapsed += 0.1 }
    }

    // MARK: The finding

    private var verdict: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            SectionHeader("Tap targets", trailing: "44pt minimum")
            Text("The dashed band is 44pt. A control drawn shorter than it is under the "
                 + "minimum comfortable hit area — measured here rather than argued from the "
                 + "token values.")
                .font(Tokens.Font.caption)
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(measured.keys.sorted(), id: \.self) { key in
                let h = measured[key] ?? 0
                HStack {
                    Text(key).font(Tokens.Font.caption)
                    Spacer()
                    Text("\(h, specifier: "%.0f")pt")
                        .font(Tokens.Font.metricInline)
                        .foregroundStyle(h >= TapTarget.minimum
                                         ? Tokens.Color.ready : Tokens.Color.failure)
                }
            }
            if measured.isEmpty {
                Text("scroll down — measurements appear as controls render")
                    .font(Tokens.Font.monoSmall).foregroundStyle(Tokens.Color.tertiaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Tokens.Space.m)
        .cardSurface()
    }

    // MARK: Tier 2 — the products PLATFORMS.md marks unverified

    private var tierTwo: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            SectionHeader("Tier 2", trailing: "unverified on touch")

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("LabeledSlider").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                LabeledSlider("Temperature", value: $temperature, in: 0...2)
                    .tapTargetBand("slider track", show: showBands, measured: $measured)
                LabeledSlider("Steps", value: $steps, in: 1...50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("ChipRow — single select").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                ChipRow(chips, selection: $chip) { $0.id.uppercased() }
                    .tapTargetBand("chip row", show: showBands, measured: $measured)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()
        }
    }

    // MARK: Tier 1 — declared portable

    private var tierOne: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            SectionHeader("Tier 1", trailing: "portable")

            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                StatusPill("Idle", status: .idle)
                StatusPill("Working", status: .working(elapsed: elapsed))
                StatusPill("Ready", status: .ready)
                StatusPill("Failed", status: .failed)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()

            MetricGrid {
                MetricTile("0.31", label: "First audio", unit: "s").carded()
                MetricTile("2.41", label: "Resident", unit: "GB",
                           caption: "1 of 1 resident").carded()
                MetricTile("−22.4", label: "Peak", unit: "dBFS",
                           emphasis: Tokens.Color.working).carded()
            }

            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                Text("AudioWaveform").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                AudioWaveform(peaks: Self.peaks).frame(height: 56)
                Separator(.horizontal)
                Text("StageStepper").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                StageStepper(progress: Self.progress)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()
        }
    }

    private static let peaks: [Float] = (0..<120).map {
        Float(abs(sin(Double($0) / 7)) * (0.3 + 0.7 * abs(cos(Double($0) / 23))))
    }

    private static let progress = StageProgress(
        nodes: [StageNode(id: "load", title: "Load"),
                StageNode(id: "encode", title: "Encode"),
                StageNode(id: "decode", title: "Decode")],
        currentIndex: 1, counterText: "2 of 3")
}

private struct Chip: Identifiable { let id: String }
