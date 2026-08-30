//
//  SliderReadout.swift
//  DesignScaffoldControls
//
//  The parts of a labeled slider that are arithmetic rather than layout — which is the
//  only reason any of this is testable.
//

import Foundation

/// Formatting and value arithmetic for ``LabeledSlider``.
public enum SliderReadout {

    /// The number as the row displays it.
    ///
    /// ## ⚠️ Not `String(format:)`
    ///
    /// All seven copies this was promoted from passed a C format string — `"%.2f"`,
    /// `"%.1f"`, `"%.0f"` — down from the call site. Three problems with that, in order of
    /// how likely they are to bite:
    ///
    /// - **It is unchecked.** `"%.2d"` against a `Double` is undefined behaviour, not a
    ///   compile error, and nothing about the call site suggests which verb is right.
    /// - **It does not localise.** `String(format:)` with no locale uses the POSIX decimal
    ///   separator, so a German user reads `0.85` where every other number on screen says
    ///   `0,85`.
    /// - **It encodes precision as a string.** `decimals` is the thing the caller actually
    ///   means, and it is an `Int` the compiler can see.
    public static func text(_ value: Double, decimals: Int, unit: String? = nil) -> String {
        let places = max(0, decimals)
        let number = value.formatted(.number.precision(.fractionLength(places)))
        guard let unit, !unit.isEmpty else { return number }
        return "\(number)\(unit)"
    }

    /// The value as the row should display it: clamped to the range, and **not** snapped
    /// to the step grid.
    ///
    /// ## ⚠️ Why there is no quantization here
    ///
    /// The first version of this did snap to the grid, on the reasoning that a readout
    /// should agree with the track beneath it. Driving the Component Lab showed that it
    /// produces the exact disagreement it was meant to prevent: a row initialised to 50 on
    /// a 0…100-by-30 slider rendered its knob at 50 — because `Slider(value:in:step:)` does
    /// not snap a value it was *given*, only values it is dragged to — while the readout
    /// confidently said 60. The readout was reporting a number the app did not hold and the
    /// control was not showing.
    ///
    /// The binding is the truth. SwiftUI already owns the stepping, and it writes stepped
    /// values back on interaction, so echoing the binding is what keeps the two in step.
    /// Clamping stays: a value outside the range renders the knob pinned to one end, and a
    /// readout that printed the out-of-range number would be describing something the
    /// control cannot show.
    ///
    /// (Measured while confirming this: when the step does not divide the range, the top of
    /// the range is genuinely unreachable — 0…100 by 30 stops at 90. That is SwiftUI's
    /// behaviour, not this component's, and the readout now follows it rather than
    /// predicting it.)
    public static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return range.lowerBound }
        return min(max(value, range.lowerBound), range.upperBound)
    }

    /// A slider position as the integer the host is actually storing.
    ///
    /// ## ⚠️ Rounds. It does not truncate.
    ///
    /// This is the one real defect the promotion found, and the two apps migrated in the
    /// same pass disagreed about it: SenseNova wrote `Int($0.rounded())` and Audio8 wrote
    /// `Int($0)`. Truncation loses a whole unit at the top of every drag — `Int(511.9999)`
    /// is 511 — and it is invisible whenever the step grid happens to land on exact
    /// integers, which is most of the time and none of the time that matters.
    ///
    /// Non-finite input is a producer bug, and it must not crash: `Int(Double.nan)` traps.
    /// An infinity still carries a direction, so it clamps to the end it points at — the
    /// first cut of this sent `+∞` to the LOW bound, which its own test caught.
    /// A NaN points nowhere, so the low bound is the arbitrary-but-safe answer.
    public static func integer(_ value: Double, in range: ClosedRange<Int>) -> Int {
        if value.isNaN { return range.lowerBound }
        let rounded = value.rounded()
        guard rounded > Double(Int.min), rounded < Double(Int.max) else {
            return rounded < 0 ? range.lowerBound : range.upperBound
        }
        return min(max(Int(rounded), range.lowerBound), range.upperBound)
    }
}
