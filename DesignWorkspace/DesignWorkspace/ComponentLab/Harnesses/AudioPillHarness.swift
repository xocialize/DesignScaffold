//
//  AudioPillHarness.swift
//  DesignWorkspace — Component Lab
//
//  ML[X] Audio Studio's `AudioActivityPill`, transcribed VERBATIM from
//  `RootView.swift:287-329` (AB-A-0036), with the pulse wiring instrumented.
//
//  Transcribed rather than approximated for the same reason the LTX clip body was: the
//  question is about THEIR code, and a version I tidied on the way in would answer a
//  different question.
//

import DesignScaffold
import DesignScaffoldProbe
import SwiftUI

struct AudioPillHarness: View {
    @State private var state: PillUnderTest.ActivityState = .idle

    private static let script: [(String, PillUnderTest.ActivityState)] = [
        ("idle", .idle),
        ("streaming 1.0", .streaming(seconds: 1.0)),
        ("streaming 2.0", .streaming(seconds: 2.0)),   // same case, new payload
        ("playing", .playing),
        ("streaming 3.0", .streaming(seconds: 3.0)),   // ⚠️ back to a pulsing state
        ("idle", .idle),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.m) {
            Text("Does the pulse restart when the state returns to `streaming` after `playing`? `pulsing` is @State set only in the dot's `.onAppear`, so the answer depends on whether SwiftUI gives each switch branch its own identity.")
                .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Tokens.Space.s) {
                ForEach(Array(Self.script.enumerated()), id: \.offset) { index, step in
                    Button(step.0) {
                        LabLog.shared.note("STATE → \(step.0)")
                        state = step.1
                    }
                    .hitTestProbe("step-\(index)")
                }
            }

            PillUnderTest(state: state)
                .padding(Tokens.Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface()
        }
    }
}

/// Verbatim, plus two `print`s. Nothing else changed.
struct PillUnderTest: View {
    enum ActivityState: Equatable {
        case idle
        case streaming(seconds: Double)
        case playing
    }

    let state: ActivityState
    @State private var pulsing = false

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .streaming(let seconds):
            pill(text: String(format: "Streaming — %.1f s", seconds),
                 color: Tokens.Color.working, pulse: true)
        case .playing:
            pill(text: "Playing", color: Tokens.Color.ready, pulse: false)
        }
    }

    private func pill(text: String, color: Color, pulse: Bool) -> some View {
        HStack(spacing: Tokens.Space.s) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .opacity(pulse && pulsing ? 0.3 : 1)
                .animation(pulse
                           ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                           : .default,
                           value: pulsing)
                .onAppear {
                    LabLog.shared.note("  onAppear fired — pulse=\(pulse), pulsing \(pulsing) → \(pulse)")
                    pulsing = pulse
                }
            Text(text)
                .font(Tokens.Font.caption)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, Tokens.Space.m)
        .padding(.vertical, Tokens.Space.s)
        .background(Tokens.Color.fillElevated, in: Capsule())
    }
}
