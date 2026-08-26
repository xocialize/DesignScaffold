import XCTest
@testable import DesignScaffoldTimeline

private struct Clip: TimelineClip, Sendable {
    let id: Int
    let start: TimeInterval
    let duration: TimeInterval
    let trackIndex: Int
}

final class TimelineGapsTests: XCTestCase {

    func testHoleBetweenTwoClipsIsAGap() {
        let clips = [Clip(id: 1, start: 0, duration: 2, trackIndex: 0),
                     Clip(id: 2, start: 4, duration: 2, trackIndex: 0)]
        XCTAssertEqual(TimelineGaps.gaps(in: clips, trackIndex: 0), [2...4])
    }

    /// The definition that matters: leading and trailing emptiness has no second anchor, so
    /// it is not a gap. The consumer's generate feature fills BETWEEN two existing clips.
    func testLeadingAndTrailingEmptinessAreNotGaps() {
        let clips = [Clip(id: 1, start: 5, duration: 2, trackIndex: 0)]
        XCTAssertTrue(TimelineGaps.gaps(in: clips, trackIndex: 0).isEmpty)
        XCTAssertTrue(TimelineGaps.gaps(in: [Clip](), trackIndex: 0).isEmpty)
    }

    func testAbuttingClipsProduceNoZeroLengthGap() {
        let clips = [Clip(id: 1, start: 0, duration: 2, trackIndex: 0),
                     Clip(id: 2, start: 2, duration: 2, trackIndex: 0)]
        XCTAssertTrue(TimelineGaps.gaps(in: clips, trackIndex: 0).isEmpty)
    }

    func testOverlappingClipsProduceNoNegativeGap() {
        let clips = [Clip(id: 1, start: 0, duration: 3, trackIndex: 0),
                     Clip(id: 2, start: 1, duration: 3, trackIndex: 0)]
        XCTAssertTrue(TimelineGaps.gaps(in: clips, trackIndex: 0).isEmpty)
    }

    /// An overlap that swallows a later clip must not open a phantom gap behind it.
    func testAContainedClipDoesNotOpenAGap() {
        let clips = [Clip(id: 1, start: 0, duration: 10, trackIndex: 0),
                     Clip(id: 2, start: 2, duration: 1, trackIndex: 0),
                     Clip(id: 3, start: 12, duration: 1, trackIndex: 0)]
        XCTAssertEqual(TimelineGaps.gaps(in: clips, trackIndex: 0), [10...12])
    }

    func testGapsAreFoundRegardlessOfDocumentOrder() {
        let inOrder = [Clip(id: 1, start: 0, duration: 2, trackIndex: 0),
                       Clip(id: 2, start: 4, duration: 2, trackIndex: 0),
                       Clip(id: 3, start: 8, duration: 2, trackIndex: 0)]
        XCTAssertEqual(TimelineGaps.gaps(in: inOrder.reversed(), trackIndex: 0), [2...4, 6...8])
    }

    func testOnlyTheRequestedTrackIsConsidered() {
        let clips = [Clip(id: 1, start: 0, duration: 2, trackIndex: 0),
                     Clip(id: 2, start: 4, duration: 2, trackIndex: 0),
                     Clip(id: 3, start: 2, duration: 2, trackIndex: 1)]   // fills track 0's hole, but on track 1
        XCTAssertEqual(TimelineGaps.gaps(in: clips, trackIndex: 0), [2...4])
    }

    func testZeroLengthClipsAreIgnored() {
        let clips = [Clip(id: 1, start: 0, duration: 2, trackIndex: 0),
                     Clip(id: 2, start: 3, duration: 0, trackIndex: 0),
                     Clip(id: 3, start: 5, duration: 2, trackIndex: 0)]
        XCTAssertEqual(TimelineGaps.gaps(in: clips, trackIndex: 0), [2...5])
    }
}

final class TimelineMarqueeTests: XCTestCase {

    private let clips = [
        Clip(id: 1, start: 0, duration: 2, trackIndex: 0),
        Clip(id: 2, start: 5, duration: 2, trackIndex: 0),
        Clip(id: 3, start: 0, duration: 20, trackIndex: 1),   // long
    ]

    /// Intersection, not containment — otherwise a clip longer than the viewport can never
    /// be marquee-selected.
    func testAMarqueeClippingACornerSelectsTheClip() {
        XCTAssertEqual(TimelineMarquee.selection(in: clips, times: 1...2, tracks: 1...1), [3])
    }

    func testSelectsOnlyWithinTheTrackSpan() {
        XCTAssertEqual(TimelineMarquee.selection(in: clips, times: 0...10, tracks: 0...0), [1, 2])
        XCTAssertEqual(TimelineMarquee.selection(in: clips, times: 0...10, tracks: 0...1), [1, 2, 3])
    }

    func testEmptyWhereNothingIntersects() {
        XCTAssertTrue(TimelineMarquee.selection(in: clips, times: 2.5...4, tracks: 0...0).isEmpty)
    }

    func testTouchingAnEdgeCounts() {
        XCTAssertEqual(TimelineMarquee.selection(in: clips, times: 2...2, tracks: 0...0), [1])
    }

    func testDragDirectionDoesNotMatter() {
        XCTAssertEqual(TimelineMarquee.range(from: 9, to: 3), 3...9)
        XCTAssertEqual(TimelineMarquee.range(from: 2, to: 0), 0...2)
    }
}
