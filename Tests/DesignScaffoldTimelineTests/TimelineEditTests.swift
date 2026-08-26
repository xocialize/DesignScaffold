import XCTest
@testable import DesignScaffoldTimeline

final class TimelineEditTests: XCTestCase {

    // MARK: Move

    func testMoveShiftsStartAndTrack() {
        let r = TimelineEdit.move(start: 10, trackIndex: 1, deltaTime: 2.5,
                                  deltaTracks: 1, trackCount: 3)
        XCTAssertEqual(r.start, 12.5, accuracy: 0.0001)
        XCTAssertEqual(r.trackIndex, 2)
    }

    func testMoveClampsStartAtZero() {
        XCTAssertEqual(TimelineEdit.move(start: 1, trackIndex: 0, deltaTime: -5,
                                         deltaTracks: 0, trackCount: 2).start, 0)
    }

    func testMoveClampsTrackInsideBounds() {
        XCTAssertEqual(TimelineEdit.move(start: 0, trackIndex: 2, deltaTime: 0,
                                         deltaTracks: 5, trackCount: 3).trackIndex, 2)
        XCTAssertEqual(TimelineEdit.move(start: 0, trackIndex: 0, deltaTime: 0,
                                         deltaTracks: -5, trackCount: 3).trackIndex, 0)
    }

    // MARK: Trim

    /// A leading trim holds the TAIL still — that is what distinguishes a trim from a move.
    func testLeadingTrimKeepsTheTailPut() {
        let r = TimelineEdit.trim(start: 10, duration: 5, edge: .leading,
                                  deltaTime: 2, minimumDuration: 0.1)
        XCTAssertEqual(r.start, 12, accuracy: 0.0001)
        XCTAssertEqual(r.duration, 3, accuracy: 0.0001)
        XCTAssertEqual(r.start + r.duration, 15, accuracy: 0.0001)   // tail unmoved
    }

    func testTrailingTrimKeepsTheHeadPut() {
        let r = TimelineEdit.trim(start: 10, duration: 5, edge: .trailing,
                                  deltaTime: -2, minimumDuration: 0.1)
        XCTAssertEqual(r.start, 10, accuracy: 0.0001)
        XCTAssertEqual(r.duration, 3, accuracy: 0.0001)
    }

    func testTrimRespectsMinimumDuration() {
        let lead = TimelineEdit.trim(start: 10, duration: 5, edge: .leading,
                                     deltaTime: 99, minimumDuration: 0.5)
        XCTAssertEqual(lead.duration, 0.5, accuracy: 0.0001)
        XCTAssertEqual(lead.start, 14.5, accuracy: 0.0001)
        let trail = TimelineEdit.trim(start: 10, duration: 5, edge: .trailing,
                                      deltaTime: -99, minimumDuration: 0.5)
        XCTAssertEqual(trail.duration, 0.5, accuracy: 0.0001)
    }

    /// A leading trim cannot drag the head before zero.
    func testLeadingTrimCannotGoNegative() {
        let r = TimelineEdit.trim(start: 1, duration: 5, edge: .leading,
                                  deltaTime: -10, minimumDuration: 0.1)
        XCTAssertEqual(r.start, 0, accuracy: 0.0001)
        XCTAssertEqual(r.duration, 6, accuracy: 0.0001)
    }

    // MARK: Cross-track resolution

    /// Rows are NOT uniform (video 64, audio 44, subtitle 28), so a fixed divisor drifts as
    /// a drag crosses rows of different kinds. The walk uses real heights.
    func testTrackDeltaWalksRealRowHeights() {
        let heights: [CGFloat] = [64, 44, 28]
        // From video(64) to audio(44): the boundary is the mean of the two, 54.
        XCTAssertEqual(TimelineEdit.trackDelta(from: 0, verticalTranslation: 53, heights: heights), 0)
        XCTAssertEqual(TimelineEdit.trackDelta(from: 0, verticalTranslation: 55, heights: heights), 1)
        // Audio(44) to subtitle(28): mean 36 — a smaller step than the first.
        XCTAssertEqual(TimelineEdit.trackDelta(from: 1, verticalTranslation: 35, heights: heights), 0)
        XCTAssertEqual(TimelineEdit.trackDelta(from: 1, verticalTranslation: 37, heights: heights), 1)
    }

    func testTrackDeltaGoesUpAndStopsAtTheEnds() {
        let heights: [CGFloat] = [64, 44, 28]
        XCTAssertEqual(TimelineEdit.trackDelta(from: 2, verticalTranslation: -40, heights: heights), -1)
        XCTAssertEqual(TimelineEdit.trackDelta(from: 0, verticalTranslation: -500, heights: heights), 0)
        XCTAssertEqual(TimelineEdit.trackDelta(from: 2, verticalTranslation: 500, heights: heights), 0)
    }

    func testTrackDeltaOutOfRangeIsZero() {
        XCTAssertEqual(TimelineEdit.trackDelta(from: 9, verticalTranslation: 100, heights: [64]), 0)
    }
}
