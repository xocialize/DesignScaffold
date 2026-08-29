//
//  StatusPillHarness.swift
//  DesignWorkspace — Component Lab
//

import Combine
import DesignScaffold
import DesignScaffoldProbe
import DesignScaffoldStatus
import SwiftUI

/// The promoted pill in every state, plus a live ticking one — the case the model tests cannot
/// reach, since "does the readout tick and the dot breathe" is not a value you can assert.
struct StatusPillHarness: View {
    @State private var elapsed: TimeInterval = 0
    @State private var live = false

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
            Spacer(minLength: 0)
        }
        .onReceive(tick) { _ in if live { elapsed += 0.1 } }
    }
}
