import XCTest
@testable import DesignScaffoldLoading

final class LoadingProgressTests: XCTestCase {

    private func progress(_ fraction: Double, fields: [String] = []) -> LoadingProgress {
        LoadingProgress(fraction: fraction, status: "Loading", fields: fields)
    }

    func testPercentFloorsSoCompletionIsHonest() {
        XCTAssertEqual(progress(0.999).percent, 99)   // never "100" before done
        XCTAssertEqual(progress(1.0).percent, 100)
        XCTAssertEqual(progress(0.291).percent, 29)
        XCTAssertEqual(progress(0).percent, 0)
    }

    /// Binary representation must not leak into the display: 0.29 × 100 is
    /// 28.999999999999996 in Double, and it has to read "29".
    func testPercentSurvivesBinaryRepresentation() {
        XCTAssertEqual(progress(0.29).percent, 29)
        XCTAssertEqual(progress(0.58).percent, 58)
        XCTAssertEqual(progress(0.07).percent, 7)
    }

    func testFractionClamps() {
        XCTAssertEqual(progress(-0.5).clampedFraction, 0)
        XCTAssertEqual(progress(1.7).clampedFraction, 1)
        XCTAssertEqual(progress(1.7).percent, 100)
        XCTAssertEqual(progress(-0.5).percent, 0)
    }

    func testNonFiniteFractionReadsAsZero() {
        XCTAssertEqual(progress(.nan).clampedFraction, 0)
        XCTAssertEqual(progress(.infinity).clampedFraction, 0)
        XCTAssertEqual(progress(.nan).percent, 0)
    }

    func testFieldsLineJoinsWithDots() {
        XCTAssertEqual(progress(0, fields: ["1.13 / 3.79 GB", "ETA 1:17"]).fieldsLine,
                       "1.13 / 3.79 GB · ETA 1:17")
    }

    func testFieldsLineDropsEmptySegmentsAndTrims() {
        XCTAssertEqual(progress(0, fields: [" 25 MB/s ", "", "   ", "ETA 1:17"]).fieldsLine,
                       "25 MB/s · ETA 1:17")
    }

    func testFieldsLineNilWhenEmpty() {
        XCTAssertNil(progress(0).fieldsLine)
        XCTAssertNil(progress(0, fields: ["", "  "]).fieldsLine)
    }
}
