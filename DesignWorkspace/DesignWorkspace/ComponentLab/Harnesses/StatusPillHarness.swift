//
//  StatusPillHarness.swift
//  DesignWorkspace — Component Lab
//

import Combine
import DesignScaffold
import DesignScaffoldProbe
import DesignScaffoldStatus
import SwiftUI

/// The promoted pill in every state, a live ticking one — the case the model tests cannot
/// reach, since "does the readout tick and the dot breathe" is not a value you can assert —
/// and, since 0.15.2, a pill that MOVES while it pulses.
///
/// ⚠️ That last case is here because its absence let a visibly broken component ship. Every
/// case above it holds the pill still, so the lab was green while Audio8 Demo rendered a
/// green dot sliding up and down its sidebar, detached from a pill reading "Ready". The
/// axis the harness could not see was the one the bug lived on — the third time this year
/// an instrument has been confidently green about something it was not looking at.
struct StatusPillHarness: View {
    @State private var elapsed: TimeInterval = 0
    @State private var live = false
    @State private var pushedDown = false

    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                Text("Every state").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                HStack(spacing: Tokens.Space.m) {
                    StatusPill("Not loaded", status: .idle)
                    StatusPill("Preparing…", status: .working())
                    StatusPill("Ready · q4", status: .ready)
                    StatusPill("Failed", status: .failed)
                }
                .hitTestProbe("states")
            }

            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                Text("Live — the dot breathes and the readout ticks. Toggle to check the pulse STARTS on a status change in place, not just on appear.")
                    .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Tokens.Space.m) {
                    StatusPill("Streaming", status: live ? .working(elapsed: elapsed) : .ready)
                        .hitTestProbe("live")
                    Button(live ? "→ ready" : "→ working") {
                        live.toggle()
                        if live { elapsed = 0 }
                        LabLog.shared.note("STATUS → \(live ? "working" : "ready")")
                    }
                    .hitTestProbe("toggle")
                }
            }
            // ⚠️ THE REGRESSION CASE. Everything above holds the pill still, which is why
            // the lab passed a component that was visibly broken in a shipping app.
            //
            // The pill breathed via `.easeInOut(…).repeatForever(autoreverses: true)`, and
            // `.animation(_:value:)` animates EVERY change in its transaction — position
            // included. So a pill that merely sat there was fine, and a pill whose
            // container relaid out while pulsing had its position swept into the repeating
            // animation: the dot left the capsule and slid up and down for the lifetime of
            // the window. Audio8 Demo shipped exactly that.
            //
            // Push the pill down WHILE it is working. The dot must stay in its capsule.
            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                Text("Regression — move the pill while it pulses. The dot must travel WITH the capsule, never separately. Set it working first, then push it down.")
                    .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Tokens.Space.m) {
                    Button(pushedDown ? "lift" : "push down") {
                        pushedDown.toggle()
                        LabLog.shared.note("LAYOUT → \(pushedDown ? "pushed" : "lifted")")
                    }
                    .hitTestProbe("push")
                    Text("dot must stay in the capsule")
                        .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.tertiaryLabel)
                }
                VStack(alignment: .leading, spacing: Tokens.Space.s) {
                    if pushedDown {
                        // Any container growth does it — this stands in for the progress row
                        // and error line that appear above Audio8's sidebar pill.
                        Color.clear.frame(height: 120)
                    }
                    StatusPill("Moving", status: live ? .working(elapsed: elapsed) : .ready)
                        .hitTestProbe("moving")
                }
                .frame(height: 180, alignment: .top)
                .padding(Tokens.Space.s)
                .cardSurface()
            }

            Spacer(minLength: 0)
        }
        .onReceive(tick) { _ in if live { elapsed += 0.1 } }
    }
}
