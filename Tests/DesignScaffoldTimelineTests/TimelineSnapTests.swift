import XCTest
@testable import DesignScaffoldTimeline

private struct Clip: TimelineClip, Sendable {
    let id: Int
    let start: TimeInterval
    let duration: TimeInterval
    let trackIndex: Int
}

final class TimelineSnapTests: XCTestCase {

    func testNearestPicksTheClosestWithinTolerance() {
        XCTAssertEqual(TimelineSnap.nearest(to: 10.2, candidates: [8, 10, 13], tolerance: 0.5), 10)
        XCTAssertNil(TimelineSnap.nearest(to: 10.9, candidates: [8, 10, 13], tolerance: 0.5))
    }

    func testZeroToleranceDisablesSnapping() {
        XCTAssertNil(TimelineSnap.nearest(to: 10, candidates: [10], tolerance: 0))
    }

    /// BOTH edges compete: snapping only the head leaves a clip's tail visibly short of the
    /// next clip's head, which is the case an editor cares most about.
    func testTrailingEdgeCanWinTheSnap() {
        // Clip 10…15. A candidate at 15.1 is 0.1 from the TAIL and 5.1 from the head.
        let snapped = TimelineSnap.snapStart(start: 10, duration: 5,
                                             candidates: [15.1], tolerance: 0.5)
        XCTAssertEqual(snapped ?? -1, 10.1, accuracy: 0.0001)   // start shifted so tail lands on 15.1
    }

    func testLeadingEdgeWinsWhenCloser() {
        let snapped = TimelineSnap.snapStart(start: 10, duration: 5,
                                             candidates: [10.1, 15.4], tolerance: 0.5)
        XCTAssertEqual(snapped ?? -1, 10.1, accuracy: 0.0001)
    }

    func testNoCandidateInRangeReturnsNil() {
        XCTAssertNil(TimelineSnap.snapStart(start: 10, duration: 5,
                                            candidates: [30], tolerance: 0.5))
    }

    // MARK: Sources

    func testClipEdgesExcludesTheDraggedClipSoItCannotSnapToItself() {
        let clips = [Clip(id: 1, start: 0, duration: 4, trackIndex: 0),
                     Clip(id: 2, start: 6, duration: 3, trackIndex: 0)]
        let all = TimelineSnapSource.clipEdges(clips).candidates(0...20)
        XCTAssertEqual(all.sorted(), [0, 4, 6, 9])
        let excluded = TimelineSnapSource.clipEdges(clips, excluding: 1).candidates(0...20)
        XCTAssertEqual(excluded.sorted(), [6, 9])
    }

    func testSourcesAreScopedToTheVisibleRange() {
        let clips = [Clip(id: 1, start: 100, duration: 4, trackIndex: 0)]
        XCTAssertTrue(TimelineSnapSource.clipEdges(clips).candidates(0...20).isEmpty)
        XCTAssertTrue(TimelineSnapSource.playhead(50).candidates(0...20).isEmpty)
        XCTAssertEqual(TimelineSnapSource.playhead(5).candidates(0...20), [5])
        XCTAssertEqual(TimelineSnapSource.origin.candidates(0...20), [0])
    }

    func testCandidatesMergeEverySource() {
        let merged = TimelineSnap.candidates(
            from: [.playhead(3), .fixed([7, 9]), .origin], in: 0...20)
        XCTAssertEqual(merged.sorted(), [0, 3, 7, 9])
    }

    /// The rule AB-A-0031 singled out, at the layer that consumes it: an 8pt tolerance is a
    /// different number of seconds at every zoom, and that is the point.
    func testToleranceComesFromPointsSoFeelIsZoomInvariant() {
        let tight = TimelineGeometry(pointsPerSecond: 400)
        let loose = TimelineGeometry(pointsPerSecond: 10)
        let candidates: [TimeInterval] = [10]
        // 0.1s away: inside 8pt at 400pt/s? 8pt = 0.02s → no. At 10pt/s, 8pt = 0.8s → yes.
        XCTAssertNil(TimelineSnap.nearest(to: 10.1, candidates: candidates,
                                          tolerance: tight.seconds(forPoints: 8)))
        XCTAssertEqual(TimelineSnap.nearest(to: 10.1, candidates: candidates,
                                            tolerance: loose.seconds(forPoints: 8)), 10)
    }
}
