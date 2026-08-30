import Foundation
import XCTest
@testable import DesignScaffoldControls

/// The arithmetic under ``LabeledSlider``. This is the half of a seven-copy promotion that
/// was actually *wrong* in the copies, rather than merely duplicated — so these are
/// regression tests for shipped bugs, not documentation of a new API.
final class SliderReadoutTests: XCTestCase {

    // MARK: Integer conversion — the bug the copies disagreed about

    /// ⚠️ Audio8's copy wrote `Int($0)`. SenseNova's wrote `Int($0.rounded())`. One of them
    /// loses a whole unit at the top of every drag, and it is invisible whenever the step
    /// grid lands on exact integers — which is most of the time, and none of the times that
    /// matter.
    func testIntegerRoundsRatherThanTruncating() {
        XCTAssertEqual(SliderReadout.integer(511.9999, in: 0...2048), 512)
        XCTAssertEqual(SliderReadout.integer(3.7, in: 0...10), 4)
        XCTAssertEqual(SliderReadout.integer(3.4, in: 0...10), 3)
        XCTAssertEqual(SliderReadout.integer(-0.6, in: -10...10), -1)
    }

    func testIntegerClampsToTheRange() {
        XCTAssertEqual(SliderReadout.integer(9_999, in: 32...2048), 2048)
        XCTAssertEqual(SliderReadout.integer(-9_999, in: 32...2048), 32)
    }

    /// Non-finite input is a producer bug. The honest answer is the low bound, not a crash —
    /// `Int(Double.nan)` traps.
    func testIntegerSurvivesNonFiniteAndEnormousInput() {
        XCTAssertEqual(SliderReadout.integer(.nan, in: 32...2048), 32)
        XCTAssertEqual(SliderReadout.integer(-.infinity, in: 32...2048), 32)
        XCTAssertEqual(SliderReadout.integer(.infinity, in: 32...2048), 2048)
        XCTAssertEqual(SliderReadout.integer(1e300, in: 32...2048), 2048)
        XCTAssertEqual(SliderReadout.integer(-1e300, in: 32...2048), 32)
    }

    // MARK: What the readout shows

    func testTheReadoutClampsToTheRange() {
        XCTAssertEqual(SliderReadout.clamp(9_999, to: 64...2048), 2048, accuracy: 1e-9)
        XCTAssertEqual(SliderReadout.clamp(-1, to: 64...2048), 64, accuracy: 1e-9)
        XCTAssertEqual(SliderReadout.clamp(0.8137, to: 0...2), 0.8137, accuracy: 1e-9)
    }

    /// ⚠️ The readout does NOT snap to the step grid, and an earlier version did — which is
    /// how it came to display 60 for a row whose binding held 50 and whose knob sat at 50.
    /// `Slider(value:in:step:)` snaps values it is DRAGGED to, never one it was handed, so
    /// a snapping readout disagrees with its own control for exactly as long as nobody has
    /// touched it. Caught by driving the Component Lab; unreachable from here, which is why
    /// this test pins the rule rather than the rendering.
    func testTheReadoutEchoesTheBindingRatherThanPredictingTheGrid() {
        XCTAssertEqual(SliderReadout.clamp(50, to: 0...100), 50, accuracy: 1e-9)
        XCTAssertEqual(SliderReadout.clamp(650, to: 64...2048), 650, accuracy: 1e-9)
    }

    func testNonFiniteReadoutFallsToTheLowBoundRatherThanPrintingNaN() {
        XCTAssertEqual(SliderReadout.clamp(.nan, to: 0...2), 0, accuracy: 1e-9)
        XCTAssertEqual(SliderReadout.clamp(.infinity, to: 0...2), 0, accuracy: 1e-9)
    }

    // MARK: Formatting

    func testDecimalsAreHonouredIncludingZero() {
        XCTAssertEqual(SliderReadout.text(0.8, decimals: 2), "0.80")
        XCTAssertEqual(SliderReadout.text(0.86, decimals: 1), "0.9")
        XCTAssertEqual(SliderReadout.text(512, decimals: 0), "512")
    }

    /// ⚠️ NOT a rounding bug, and the first version of the test above asserted it was:
    /// `0.85` is not representable in binary — the stored value is `0.8499999…` — so it
    /// rounds DOWN to `0.8` at one decimal place, and would in any formatter. Do not
    /// "fix" this by changing the rounding rule; pin it so the next reader does not try.
    func testHalfWayLookingValuesFollowTheirActualBinaryValue() {
        XCTAssertEqual(SliderReadout.text(0.85, decimals: 1), "0.8")
        // Control, and it needs a high-precision expansion to show anything: `Decimal(0.85)`
        // and `"\(0.85)"` both re-round to "0.85" and would have "proved" the opposite.
        // (`String(format:)` is banned for DISPLAY, not for introspecting a bit pattern.)
        XCTAssertTrue(String(format: "%.17f", 0.85).hasPrefix("0.8499"),
                      "the stored value really is below 0.85: \(String(format: "%.17f", 0.85))")
    }

    /// Negative precision is a caller slip; it must not produce a mangled string.
    func testNegativeDecimalsClampToZero() {
        XCTAssertEqual(SliderReadout.text(3.7, decimals: -2), "4")
    }

    func testAUnitIsAppendedAndAnEmptyOneIsNot() {
        XCTAssertEqual(SliderReadout.text(2, decimals: 1, unit: "×"), "2.0×")
        XCTAssertEqual(SliderReadout.text(2, decimals: 1, unit: ""), "2.0")
        XCTAssertEqual(SliderReadout.text(2, decimals: 1, unit: nil), "2.0")
    }

    /// ⚠️ The reason this is not `String(format:)`: that uses the POSIX decimal separator
    /// regardless of locale, so a German user would read `0.85` in a panel where every
    /// other number says `0,85`.
    func testFormattingFollowsTheLocaleRatherThanPOSIX() {
        let german = 0.85.formatted(.number.precision(.fractionLength(2))
            .locale(Locale(identifier: "de_DE")))
        XCTAssertTrue(german.contains(","), "expected a comma separator, got \(german)")
        XCTAssertEqual(String(format: "%.2f", 0.85), "0.85",
                       "control: String(format:) is POSIX and does not move")
    }
}
