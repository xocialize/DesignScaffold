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

    /// A dot for every status but one. `attention` shares `working`'s colour, so it is drawn as
    /// a badge glyph — the distinction has to survive a still screenshot, and colour alone would
    /// not. The branch is on the pill's own value and the marker carries no gesture, so a swap
    /// between branches costs nothing (AB-L-0061 is about gestures dying on a rebuild).
    private var markerSize: CGFloat {
        theme.symbol(for: status) == nil ? theme.dotSize : theme.dotSize + 4
    }

    @ViewBuilder
    private var marker: some View {
        if let symbol = theme.symbol(for: status) {
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(theme.color(for: status))
        } else {
            Circle().fill(theme.color(for: status))
        }
    }

    private var text: String {
        guard let elapsed = status.elapsed else { return label }
        return "\(label) — \(StatusFormat.elapsed(elapsed))"
    }

    private var dot: some View {
        // ⚠️ NO implicit animation here, and never add one — see ``Pulse``. The previous
        // version breathed via `.easeInOut(…).repeatForever(autoreverses: true)`, which
        // swept the dot's POSITION into the repeating animation the first time the pill's
        // container relaid out. The dot left the pill and slid up and down the window for
        // as long as it was open.
        TimelineView(Pulse.schedule(active: status.pulses, reduceMotion: reduceMotion)) { context in
            marker
                // A glyph needs more than a dot's 6pt to read as a badge; +4 keeps it inside
                // the caption's line height so the pill does not change height per status.
                .frame(width: markerSize, height: markerSize)
                .opacity(Pulse.opacity(at: context.date,
                                       active: status.pulses,
                                       reduceMotion: reduceMotion,
                                       duration: theme.pulseDuration,
                                       minOpacity: theme.pulseMinOpacity,
                                       reducedMotionOpacity: theme.reducedMotionOpacity))
        }
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
