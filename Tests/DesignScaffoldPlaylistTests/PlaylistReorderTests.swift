import XCTest
@testable import DesignScaffoldPlaylist

private struct Row: Identifiable, Equatable {
    let id: Int
}

final class PlaylistReorderTests: XCTestCase {

    private func rows(_ ids: Int...) -> [Row] { ids.map(Row.init) }
    private func ids(_ rows: [Row]) -> [Int] { rows.map(\.id) }

    func testMoveDownwardLandsAfterTarget() {
        var list = rows(1, 2, 3, 4, 5)
        XCTAssertTrue(PlaylistReorder.liveMove(&list, dragging: 1, over: 3))
        XCTAssertEqual(ids(list), [2, 3, 1, 4, 5])
    }

    func testMoveUpwardLandsAtTarget() {
        var list = rows(1, 2, 3, 4, 5)
        XCTAssertTrue(PlaylistReorder.liveMove(&list, dragging: 4, over: 2))
        XCTAssertEqual(ids(list), [1, 4, 2, 3, 5])
    }

    func testAdjacentSwapDownward() {
        var list = rows(1, 2, 3)
        XCTAssertTrue(PlaylistReorder.liveMove(&list, dragging: 1, over: 2))
        XCTAssertEqual(ids(list), [2, 1, 3])
    }

    func testAdjacentSwapUpward() {
        var list = rows(1, 2, 3)
        XCTAssertTrue(PlaylistReorder.liveMove(&list, dragging: 2, over: 1))
        XCTAssertEqual(ids(list), [2, 1, 3])
    }

    func testMoveToEnds() {
        var list = rows(1, 2, 3, 4)
        XCTAssertTrue(PlaylistReorder.liveMove(&list, dragging: 1, over: 4))
        XCTAssertEqual(ids(list), [2, 3, 4, 1])
        XCTAssertTrue(PlaylistReorder.liveMove(&list, dragging: 1, over: 2))
        XCTAssertEqual(ids(list), [1, 2, 3, 4])
    }

    func testSameRowIsNoOp() {
        var list = rows(1, 2, 3)
        XCTAssertFalse(PlaylistReorder.liveMove(&list, dragging: 2, over: 2))
        XCTAssertEqual(ids(list), [1, 2, 3])
    }

    func testUnknownIdsAreNoOps() {
        var list = rows(1, 2, 3)
        XCTAssertFalse(PlaylistReorder.liveMove(&list, dragging: 99, over: 2))
        XCTAssertFalse(PlaylistReorder.liveMove(&list, dragging: 1, over: 99))
        XCTAssertEqual(ids(list), [1, 2, 3])
    }

    /// A full drag pass — the dragged row entering each neighbour in turn — must end
    /// with the row at the final hover position (the live-reorder invariant).
    func testSequentialDragPassIsStable() {
        var list = rows(1, 2, 3, 4)
        PlaylistReorder.liveMove(&list, dragging: 1, over: 2)   // [2,1,3,4]
        PlaylistReorder.liveMove(&list, dragging: 1, over: 3)   // [2,3,1,4]
        PlaylistReorder.liveMove(&list, dragging: 1, over: 4)   // [2,3,4,1]
        XCTAssertEqual(ids(list), [2, 3, 4, 1])
    }
}

// MARK: - Relative placement
//
// The filter-safe report. These exist because a playlist that gains filters is the normal
// direction of travel, and an absolute order silently discards the positions of rows the
// user cannot see.

extension PlaylistReorderTests {

    private struct Row: Identifiable, Equatable { let id: Int }

    func testPlacementReportsThePrecedingRow() {
        let rows = [Row(id: 1), Row(id: 2), Row(id: 3)]
        XCTAssertEqual(PlaylistReorder.placement(rows, moved: 3),
                       .init(moved: 3, after: 2))
    }

    func testPlacementAtTheFrontHasNoPredecessor() {
        let rows = [Row(id: 9), Row(id: 1), Row(id: 2)]
        XCTAssertEqual(PlaylistReorder.placement(rows, moved: 9),
                       .init(moved: 9, after: nil),
                       "nil means first among the rows SHOWN, which is all a filtered list can say")
    }

    func testPlacementOfAnAbsentRowIsNil() {
        XCTAssertNil(PlaylistReorder.placement([Row(id: 1)], moved: 42))
    }

    /// The whole point: the same drag over a FILTERED list yields a placement a host can apply
    /// to its full model, where an absolute order could not.
    func testPlacementSurvivesAFilter() {
        let full = [Row(id: 1), Row(id: 2), Row(id: 3), Row(id: 4)]
        // The host shows only the odd rows, and the user drags 3 above 1.
        var shown = full.filter { $0.id % 2 == 1 }          // [1, 3]
        PlaylistReorder.liveMove(&shown, dragging: 3, over: 1)
        let placement = PlaylistReorder.placement(shown, moved: 3)
        XCTAssertEqual(placement, .init(moved: 3, after: nil))

        // Applying THAT to the full list keeps 2 and 4 where they were.
        var resolved = full
        resolved.removeAll { $0.id == 3 }
        resolved.insert(Row(id: 3), at: 0)
        XCTAssertEqual(resolved.map(\.id), [3, 1, 2, 4])

        // Whereas the visible order alone claims the list is [3, 1] — losing 2 and 4 entirely.
        XCTAssertEqual(shown.map(\.id), [3, 1])
    }
}
