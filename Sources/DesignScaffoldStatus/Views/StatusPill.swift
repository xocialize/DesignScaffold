//
//  StatusPill.swift
//  DesignScaffoldStatus
//
//  A dot, a label, a capsule.
//

import DesignScaffold
import SwiftUI

/// Reports what something is doing: idle, working, ready, or failed.
///
/// ```swift
/// StatusPill("Ready · q4", status: .ready)
/// StatusPill("Streaming", status: .working(elapsed: seconds))
/// ```
///
/// ## Promoted from eight copies
///
/// The fleet's most-duplicated UI atom, found by a survey rather than proposed: ModelSheetStudio
/// (twice), ML[X] Media Forge's ForgeUI, MageVL, Nemotron ASR, Qwen Image, LLM Voice Chat, and
/// ML[X] Audio Studio. **Two of them are byte-identical**, which means one was copied from the
/// other and neither knew.
///
/// They agreed on nearly everything — a 6pt dot, caption text, a capsule on an elevated fill.
/// Two things they did not agree on are the reason this exists:
///
/// ⚠️ **Four took a `Color` from the call site.** That puts the semantic decision at every use,
/// which is how a fleet acquires several greens that all mean "ready". Here the status picks
/// the colour from the tokens that were put there for it.
///
/// ⚠️ **Two pulse rhythms.** ML[X] Audio Studio's breathes at 0.6s to 0.3 opacity;
/// ``StageStepper`` shipped at 0.9s to 0.15. Both now read `Tokens.Motion`, so "work in flight"
/// looks the same in every window.
///
/// ## What a host still owns
///
/// The **label**. Every copy composed its own — `"Ready · \(quant)"`, `"Download needed"`,
/// `"Streaming"` — and that is app vocabulary, not design vocabulary. A tooltip is the host's
/// too: apply `.help(_:)` yourself, as MageVL's copy does.
public struct StatusPill: View {

    private let label: String
    private let status: Status
    var themeOverride: StatusPillTheme?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var theme: StatusPillTheme { themeOverride ?? .scaffold }

    public init(_ label: String, status: Status) {
        self.label = label
        self.status = status
    }

    public var body: some View {
        HStack(spacing: theme.spacing) {
            dot
            Text(text)
                .font(theme.font)
                .foregroundStyle(theme.text)
                // Live seconds tick; proportional digits make them jitter, and the movement
                // reads as instability in the thing being measured.
                .monospacedDigit()
        }
        .padding(.horizontal, theme.horizontalPadding)
        .padding(.vertical, theme.verticalPadding)
        .background(theme.fill, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(text))
    }

    private var text: String {
        guard let elapsed = status.elapsed else { return label }
        return "\(label) — \(StatusFormat.elapsed(elapsed))"
    }

    private var dot: some View {
        Circle()
            .fill(theme.color(for: status))
            .frame(width: theme.dotSize, height: theme.dotSize)
            // ⚠️ Under Reduce Motion the dot holds a STEADY, slightly-faded opacity rather than
            // full: it still has to read as active when it cannot breathe, and a pulse that
            // simply stops is indistinguishable from one that finished.
            .opacity(pulseOpacity)
            .animation(shouldPulse
                       ? .easeInOut(duration: theme.pulseDuration).repeatForever(autoreverses: true)
                       : .default,
                       value: breathing)
            // Keyed on `shouldPulse`, NOT `onAppear`. A pill whose status changes in place —
            // which is the normal case, since a host binds one pill to a changing value — may
            // not be rebuilt, and an `onAppear`-only pulse would never start.
            .onChange(of: shouldPulse, initial: true) { _, pulsing in
                breathing = pulsing
            }
    }

    private var shouldPulse: Bool { status.pulses && !reduceMotion }

    private var pulseOpacity: Double {
        if status.pulses && reduceMotion { return theme.reducedMotionOpacity }
        return shouldPulse && breathing ? theme.pulseMinOpacity : 1
    }
}

// MARK: - Chainable configuration

public extension StatusPill {
    /// Override the visual theme. Without this, ``StatusPillTheme/scaffold`` is used.
    func theme(_ theme: StatusPillTheme) -> StatusPill {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}
