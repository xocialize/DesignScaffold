import XCTest
@testable import DesignScaffoldChips

final class ChipFlowTests: XCTestCase {

    func testChipsThatFitStayOnOneRow() {
        XCTAssertEqual(ChipFlow.rows(widths: [40, 50, 60], maxWidth: 200, spacing: 4),
                       [[0, 1, 2]])
    }

    func testWrapsWhenTheRowRunsOut() {
        // 40 + 4 + 50 = 94 fits; adding 4 + 60 = 158 does not fit in 100.
        XCTAssertEqual(ChipFlow.rows(widths: [40, 50, 60], maxWidth: 100, spacing: 4),
                       [[0, 1], [2]])
    }

    /// Spacing counts toward the width — forgetting it is the classic off-by-one wrap.
    func testSpacingIsCountedWhenDecidingToWrap() {
        // Exactly 100 of chips; with 4pt spacing the pair no longer fits in 100.
        XCTAssertEqual(ChipFlow.rows(widths: [50, 50], maxWidth: 100, spacing: 4),
                       [[0], [1]])
        XCTAssertEqual(ChipFlow.rows(widths: [50, 50], maxWidth: 104, spacing: 4),
                       [[0, 1]])
    }

    /// A chip wider than the row keeps its own row rather than vanishing.
    func testAnOversizeChipGetsItsOwnRowRatherThanBeingDropped() {
        let rows = ChipFlow.rows(widths: [40, 500, 40], maxWidth: 100, spacing: 4)
        XCTAssertEqual(rows, [[0], [1], [2]])
        XCTAssertEqual(rows.flatMap { $0 }.count, 3, "no chip may be lost")
    }

    func testEmptyInput() {
        XCTAssertTrue(ChipFlow.rows(widths: [], maxWidth: 100, spacing: 4).isEmpty)
    }

    func testEveryChipAppearsExactlyOnce() {
        let widths: [CGFloat] = [30, 80, 45, 60, 25, 90]
        let flat = ChipFlow.rows(widths: widths, maxWidth: 150, spacing: 6).flatMap { $0 }
        XCTAssertEqual(flat.sorted(), Array(widths.indices))
    }

    func testHeightCountsTheGapsBetweenRows() {
        XCTAssertEqual(ChipFlow.height(rowCount: 1, chipHeight: 20, spacing: 4), 20)
        XCTAssertEqual(ChipFlow.height(rowCount: 3, chipHeight: 20, spacing: 4), 68)
        XCTAssertEqual(ChipFlow.height(rowCount: 0, chipHeight: 20, spacing: 4), 0)
    }
}
