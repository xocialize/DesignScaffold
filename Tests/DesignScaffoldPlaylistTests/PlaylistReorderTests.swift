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
