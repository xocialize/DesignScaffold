import XCTest
@testable import DesignScaffoldTimeline

final class TimecodeTests: XCTestCase {

    func testExactMatchesTheSpecReadout() {
        // The artboard's readout: 00:00:04:12 at 24fps = 4.5s
        XCTAssertEqual(Timecode(frameRate: 24).exact(4.5), "00:00:04:12")
    }

    func testExactCarriesHoursAndFrames() {
        let tc = Timecode(frameRate: 30)
        XCTAssertEqual(tc.exact(3661.5), "01:01:01:15")
        XCTAssertEqual(tc.exact(0), "00:00:00:00")
    }

    func testNegativeClampsRatherThanRenderingASign() {
        XCTAssertEqual(Timecode().exact(-5), "00:00:00:00")
    }

    func testInvalidFrameRateFallsBack() {
        XCTAssertEqual(Timecode(frameRate: 0).frameRate, 24)
    }

    func testRulerLabelsAreCompact() {
        let tc = Timecode()
        XCTAssertEqual(tc.label(4, interval: 2), "00:04")
        XCTAssertEqual(tc.label(125, interval: 5), "02:05")
        XCTAssertEqual(tc.label(3725, interval: 60), "1:02:05")
    }

    /// Sub-second intervals need a decimal, or every tick in view reads identically.
    func testSubSecondIntervalsShowFractions() {
        XCTAssertEqual(Timecode().label(4.5, interval: 0.5), "0:04.5")
        XCTAssertNotEqual(Timecode().label(4.5, interval: 0.5),
                          Timecode().label(4.0, interval: 0.5))
    }
}
