//
//  WaveformHarness.swift
//  DesignWorkspace — Component Lab
//

import Combine
import DesignScaffold
import DesignScaffoldProbe
import DesignScaffoldTimeline
import DesignScaffoldWaveform
import SwiftUI

struct WaveformHarness: View {
    @State private var live: [Float] = []
    @State private var running = false
    @State private var phase = 0.0
    @State private var geometry = TimelineGeometry(pointsPerSecond: 60)
    @State private var playhead: TimeInterval = 0
    @State private var selection: Set<Int> = []

    private let tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    /// A synthetic asset: a slow swell with three sharp transients, so a MEAN-bucketed
    /// waveform would visibly lose the hits a MAX-bucketed one keeps.
    private static let asset: [Float] = (0..<4000).map { i in
        let swell = Float(0.25 + 0.2 * sin(Double(i) / 500))
        let isHit = [800, 2000, 3200].contains { abs($0 - i) < 3 }
        return isHit ? 1.0 : swell
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            section("Live level meter — newest at the right edge") {
                HStack(spacing: Tokens.Space.m) {
                    AudioLevelMeter(levels: live, isActive: running)
                        .frame(width: 320, height: 34)
                        .padding(Tokens.Space.s).cardSurface()
                        .hitTestProbe("meter")
                    Button(running ? "stop" : "start") {
                        running.toggle()
                        LabLog.shared.note("METER \(running ? "running" : "stopped") — \(live.count) levels")
                    }
                    .hitTestProbe("meter-toggle")
                    Text("\(live.count) levels").font(Tokens.Font.monoSmall)
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                }
            }

            section("Track waveform at three widths — the SAME 4000 peaks, re-bucketed to fit") {
                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    ForEach([460, 220, 90], id: \.self) { w in
                        AudioTrackWaveform(peaks: Self.asset)
                            .frame(width: CGFloat(w), height: 40)
                            .padding(Tokens.Space.xs).cardSurface()
                    }
                }
            }

            section("Inside a timeline clip — zoom and the waveform re-buckets with the width") {
                TimelineView(tracks: [TimelineTrack(id: "a1", name: "A1", kind: .audio)],
                             clips: [WaveClip(id: 1, start: 0.5, duration: 4, trackIndex: 0)],
                             geometry: $geometry, playhead: $playhead, selection: $selection) { _ in
                    ZStack {
                        Tokens.Color.accent.opacity(0.18)
                        AudioTrackWaveform(peaks: Self.asset).theme(.track)
                            .padding(.vertical, Tokens.Space.xs)
                    }
                }
                .frame(height: 120)
                HStack(spacing: Tokens.Space.s) {
                    Button("zoom out") { geometry.pointsPerSecond = max(10, geometry.pointsPerSecond / 2) }
                        .hitTestProbe("zoom-out")
                    Button("zoom in") { geometry.pointsPerSecond = min(400, geometry.pointsPerSecond * 2) }
                        .hitTestProbe("zoom-in")
                    Text("\(Int(geometry.pointsPerSecond)) pt/s").font(Tokens.Font.monoSmall)
                        .foregroundStyle(Tokens.Color.tertiaryLabel)
                }
            }
            Spacer(minLength: 0)
        }
        .onReceive(tick) { _ in
            guard running else { return }
            phase += 0.28
            let level = Float(abs(sin(phase)) * (0.35 + 0.55 * abs(sin(phase / 7))))
            live = AudioPeaks.rolling(live, appending: level, limit: 120)
        }
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text(title).font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
            content()
        }
    }
}

nonisolated struct WaveClip: TimelineClip, Sendable {
    let id: Int
    var start: TimeInterval
    var duration: TimeInterval
    var trackIndex: Int
}
