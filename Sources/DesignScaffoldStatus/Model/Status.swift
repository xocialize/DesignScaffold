//
//  Status.swift
//  DesignScaffoldStatus
//

import Foundation

/// What a ``StatusPill`` is reporting.
///
/// State-driven rather than colour-driven, deliberately. Four of the eight copies this was
/// promoted from took a `Color` from the call site, which puts the semantic decision at every
/// use — and is how a fleet ends up with several greens that all mean "ready".
public enum Status: Equatable, Sendable {
    /// Nothing happening. Not an error, and not success.
    case idle
    /// Work in flight. Pulses, and shows `elapsed` seconds when the host supplies them.
    case working(elapsed: TimeInterval? = nil)
    /// Done, loaded, connected.
    case ready
    /// Working, but not on the good path — and the user should know.
    ///
    /// ## Promoted from two independent needs, both of which had to say it without help
    ///
    /// **MarqueeSurface** has a connection state whose `.offline` means *amber, still
    /// playing*: last-known-good cached content, explicitly neither idle nor failed. It kept
    /// an app-composed pill rather than lie with `ready` (green), `failed` (dead) or `idle`
    /// (loses the amber) — and filed AB-A-0042 rather than inventing one.
    ///
    /// **ModelSheetStudio** independently grew `Availability.degraded(whyNot:fallback:)`,
    /// which reports `isUsable: true` and renders amber. Same semantic, different domain.
    ///
    /// ⚠️ It does NOT pulse. Degraded is a settled state — the system is not working toward
    /// anything, it has arrived somewhere worse. A pulse would say "hold on", and the honest
    /// message is "this is how it is now".
    ///
    /// Any *reason* belongs in the label, which the host owns. ModelSheetStudio's
    /// `whyNot`/`fallback` payload feeds a tooltip, not the badge text, which is why this
    /// case carries nothing.
    ///
    /// **Not usable at all?** That is ``attention``, not this.
    case degraded
    /// Settled, and waiting on a person — a folder to choose, weights to download, an
    /// artifact to rebuild. **Not usable until they act; nothing went wrong.**
    ///
    /// ## The gap between `degraded` and `failed`, found by three apps independently
    ///
    /// - **ML[X] Audio Studio** (AB-A-0060): a `Character` whose description was edited is
    ///   `invalidated` — "listed, amber, not renderable". Its pill said `.failed`, red, the only
    ///   element in the view disagreeing with the three amber ones beside it. Nothing failed.
    /// - **Audio8 Demo**: `needsFolder` / `needsDownload` were mapped to `.working()` because
    ///   grey read as settled and there was nothing amber that did not pulse — so a state
    ///   that is waiting on the *user* breathed "hold on" at them indefinitely.
    /// - **ModelSheetStudio**: `availableAfterEvict` renders amber with a badge glyph.
    ///
    /// `degraded` does not fit: both of its promotions were `isUsable: true`, and widening it
    /// would make "can I use this?" unanswerable from the state. This is the fifth thing.
    ///
    /// ⚠️ **Told apart by SHAPE, not colour.** It shares `working`'s amber — the conventional
    /// "needs attention" hue — so the pill draws a badge glyph (`exclamationmark.circle.fill`)
    /// instead of a dot, the way two of the three sources already did. A still screenshot can
    /// tell it from `working`; that was the bar set for `degraded` and it holds here.
    ///
    /// It does not pulse: a pulse says "hold on", and the honest message is "over to you".
    case attention
    /// It went wrong.
    case failed

    /// Only work in flight breathes.
    ///
    /// A pulse means "this is still going", so attaching it to a settled state would be a lie
    /// the user has to learn to ignore.
    public var pulses: Bool {
        if case .working = self { return true }
        return false
    }

    /// The live seconds to render, when there are any.
    public var elapsed: TimeInterval? {
        if case .working(let seconds) = self { return seconds }
        return nil
    }
}

public enum StatusFormat {
    /// `12.4 s` — one decimal, which is what a live readout can honestly claim.
    ///
    /// ⚠️ Pair with `.monospacedDigit()` at the call site, which ``StatusPill`` does. Live
    /// numbers in proportional digits jitter as they tick, and the movement reads as
    /// instability in the thing being measured rather than in the label.
    public static func elapsed(_ seconds: TimeInterval) -> String {
        String(format: "%.1f s", max(0, seconds))
    }
}
