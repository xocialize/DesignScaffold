//
//  ⚠️ macOS-only. This target is wrapped in `#if os(macOS)` because it is built on AppKit
//  API with no iOS equivalent — see `Docs/PLATFORMS.md`. On iOS the module compiles to
//  nothing, so an app that adds this product by mistake gets "cannot find X in scope"
//  rather than a wall of AppKit errors, and the package as a whole still builds.
//
#if os(macOS)

import CoreGraphics
import Foundation

/// Chooses the ruler's tick interval for the current zoom, so labels stay legible and the
/// interval reads as a round number instead of an artefact of the zoom level.
///
/// Pure and unit-tested: this is the kind of arithmetic that looks obviously right and is
/// off by one ladder rung at the extremes.
public enum TickScale {

    /// Round intervals a person reads without decoding — sub-second for frame-level zoom,
    /// then seconds, then the clock units.
    public static let ladder: [TimeInterval] = [
        0.1, 0.25, 0.5, 1, 2, 5, 10, 15, 30,
        60, 120, 300, 600, 900, 1800, 3600, 7200,
    ]

    /// The smallest ladder interval whose spacing is at least `minSpacing` points.
    /// Falls back to the coarsest rung when even that is too tight (zoomed all the way out).
    public static func interval(pointsPerSecond: CGFloat, minSpacing: CGFloat) -> TimeInterval {
        guard pointsPerSecond > 0 else { return ladder.last! }
        for candidate in ladder where CGFloat(candidate) * pointsPerSecond >= minSpacing {
            return candidate
        }
        return ladder.last!
    }

    /// Tick times covering `range` at `interval`, aligned to whole multiples of the
    /// interval so ticks land on round times rather than on the scroll position.
    public static func ticks(in range: ClosedRange<TimeInterval>,
                             interval: TimeInterval) -> [TimeInterval] {
        // No inverted-range guard: ClosedRange enforces lower <= upper at construction,
        // so such a branch would be unreachable code pretending to be defensive.
        guard interval > 0 else { return [] }
        // Start at the aligned tick AT OR BEFORE the lower bound and always include it:
        // its label is drawn to the right of the tick, so a tick just off the left edge
        // can still have a visible label. Including it unconditionally is what makes the
        // ruler stable — an earlier version admitted it only within half an interval,
        // which made the leading label blink in and out depending on where in the interval
        // the scroll position happened to sit.
        var t = (range.lowerBound / interval).rounded(.down) * interval
        var out: [TimeInterval] = []
        // Bounded: a viewport cannot hold more ticks than this without being illegible,
        // and it keeps a pathological interval from spinning.
        while t <= range.upperBound && out.count < 512 {
            out.append(t)
            t += interval
        }
        return out
    }
}

#endif
