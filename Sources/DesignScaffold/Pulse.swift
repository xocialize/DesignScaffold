//
//  Pulse.swift
//  DesignScaffold
//
//  The breathing that says "still working" — computed from a clock, never from an
//  implicit animation.
//

import Foundation
import SwiftUI

/// The opacity of a pulsing indicator, as a function of time.
///
/// ```swift
/// TimelineView(Pulse.schedule(active: status.pulses, reduceMotion: reduceMotion)) { context in
///     Circle()
///         .fill(tint)
///         .frame(width: 6, height: 6)
///         .opacity(Pulse.opacity(at: context.date,
///                                active: status.pulses,
///                                reduceMotion: reduceMotion))
/// }
/// ```
///
/// ## ⚠️ Why this is a clock, and why an implicit animation is banned here
///
/// It used to be an implicit animation. Both ``StatusPill`` and ``StageStepper`` wrote the
/// obvious thing:
///
/// ```swift
/// .opacity(breathing ? theme.pulseMinOpacity : 1)
/// .animation(.easeInOut(duration: …).repeatForever(autoreverses: true), value: breathing)
/// ```
///
/// `.animation(_:value:)` does not animate only the property you had in mind. It animates
/// **every** animatable change to that subtree that lands in the same transaction —
/// **position included**. So the first time the indicator's container relaid out while the
/// pulse was live — a progress row appearing above it, an error line arriving, a sidebar
/// resizing — the dot's position was swept into the repeating animation. And an animation
/// that both repeats forever and autoreverses, once it owns a geometry property, never
/// settles: it ping-pongs the view between the old layout position and the new one for the
/// lifetime of the window.
///
/// This is observed, not theorised. Audio8 Demo shipped it: a 6pt green dot travelling up
/// and down the sidebar's left edge, while its pill sat at the bottom reading "Ready" with
/// an empty socket where the dot belonged.
///
/// A clock cannot do that. `TimelineView` hands you a new date, the opacity is recomputed,
/// and **nothing is interpolated** — so nothing can leak into layout. The pulse also stops
/// being a side effect and becomes a pure function, which is the only reason its shape is
/// now under test at all: the bug it replaces was invisible to every test that could have
/// been written, because it lived in geometry the component never asked to animate.
///
/// **Do not reintroduce an implicit animation on a pulsing indicator.** If you need one
/// somewhere else, keep it off any view whose position its container can change.
public enum Pulse {

    /// The `TimelineView` schedule to pair with ``opacity(at:active:reduceMotion:duration:minOpacity:maxOpacity:reducedMotionOpacity:)``.
    ///
    /// Paused when there is nothing to animate, so a settled indicator costs no frames —
    /// and under Reduce Motion, where the opacity is a constant.
    public static func schedule(active: Bool, reduceMotion: Bool) -> AnimationTimelineSchedule {
        .animation(paused: !shouldTick(active: active, reduceMotion: reduceMotion))
    }

    /// Whether the clock should run at all.
    ///
    /// Split out of ``schedule(active:reduceMotion:)`` because a `TimelineSchedule` does not
    /// report whether it is paused, so this is the only part of the decision a test can see —
    /// and "does a settled pill spend frames" is worth pinning.
    public static func shouldTick(active: Bool, reduceMotion: Bool) -> Bool {
        active && !reduceMotion
    }

    /// The indicator's opacity at `date`.
    ///
    /// - Parameters:
    ///   - active: Whether the thing being reported is still in flight. Only work in
    ///     flight breathes — a pulse on a settled state is a lie the user learns to ignore.
    ///   - reduceMotion: From `\.accessibilityReduceMotion`.
    ///   - maxOpacity: The top of the breath. 1 for a filled dot; ``StageStepper``'s ring
    ///     rests slightly under full.
    public static func opacity(
        at date: Date,
        active: Bool,
        reduceMotion: Bool,
        duration: Double = Tokens.Motion.pulseDuration,
        minOpacity: Double = Tokens.Motion.pulseMinOpacity,
        maxOpacity: Double = 1,
        reducedMotionOpacity: Double = Tokens.Motion.reducedMotionOpacity
    ) -> Double {
        guard active else { return maxOpacity }
        // ⚠️ Under Reduce Motion the indicator holds a STEADY, slightly-faded opacity
        // rather than full: it still has to read as active when it cannot breathe, and a
        // pulse that simply stops is indistinguishable from one that finished.
        guard !reduceMotion else { return reducedMotionOpacity }
        // A zero or negative duration would divide by zero below. It is a caller bug, and
        // the honest failure is "no pulse", not a crash or a flicker.
        guard duration > 0, minOpacity < maxOpacity else { return maxOpacity }

        // A full breath is out AND back — `duration` each way, which is what
        // `autoreverses: true` meant when this was an animation.
        let period = duration * 2
        let phase = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: period) / period
        // Raised cosine: 0 at both ends, 1 half way. That reproduces the ease-in-out shape
        // at each turning point that autoreverse gave, without an animation to give it.
        let eased = (1 - cos(phase * 2 * .pi)) / 2
        return maxOpacity - eased * (maxOpacity - minOpacity)
    }
}
