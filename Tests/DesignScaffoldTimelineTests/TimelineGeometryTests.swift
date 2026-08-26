import XCTest
@testable import DesignScaffoldTimeline

final class TimelineGeometryTests: XCTestCase {

    private func geo(_ pps: CGFloat = 40, start: TimeInterval = 0, width: CGFloat = 800)
        -> TimelineGeometry {
        TimelineGeometry(pointsPerSecond: pps, visibleStart: start, viewportWidth: width)
    }

    func testTimeAndPointsRoundTrip() {
        let g = geo(40, start: 12)
        XCTAssertEqual(g.x(for: 12), 0, accuracy: 0.001)
        XCTAssertEqual(g.x(for: 13), 40, accuracy: 0.001)
        XCTAssertEqual(g.time(atX: 40), 13, accuracy: 0.001)
        XCTAssertEqual(g.time(atX: g.x(for: 17.5)), 17.5, accuracy: 0.001)
    }

    /// THE requirement from AB-A-0031: a threshold in POINTS must mean the same *feel* at
    /// every zoom, which means the seconds it converts to change with zoom.
    func testSnapThresholdIsConstantInPointsAcrossZoom() {
        XCTAssertEqual(geo(10).seconds(forPoints: 8), 0.8, accuracy: 0.0001)
        XCTAssertEqual(geo(40).seconds(forPoints: 8), 0.2, accuracy: 0.0001)
        XCTAssertEqual(geo(400).seconds(forPoints: 8), 0.02, accuracy: 0.0001)
        // The failure mode this replaces: a hardcoded 0.2s is 2pt at 10pps (imperceptible)
        // and 80pt at 400pps (grabs everything).
        XCTAssertEqual(geo(10).width(for: 0.2), 2, accuracy: 0.001)
        XCTAssertEqual(geo(400).width(for: 0.2), 80, accuracy: 0.001)
    }

    func testZoomIsClamped() {
        var g = geo()
        g.zoom(to: 10_000, keeping: 0)
        XCTAssertEqual(g.pointsPerSecond, TimelineGeometry.maxPointsPerSecond)
        g.zoom(to: 0.001, keeping: 0)
        XCTAssertEqual(g.pointsPerSecond, TimelineGeometry.minPointsPerSecond)
    }

    /// Zoom must keep the anchor time under the same x, or the content teleports.
    func testZoomKeepsAnchorPinned() {
        var g = geo(40, start: 10)
        let anchor: TimeInterval = 15
        let before = g.x(for: anchor)
        g.zoom(to: 120, keeping: anchor)
        XCTAssertEqual(g.x(for: anchor), before, accuracy: 0.001)
    }

    func testScrollNeverGoesNegative() {
        var g = geo()
        g.scroll(to: -50)
        XCTAssertEqual(g.visibleStart, 0)
    }

    func testVisibilityIsInclusiveOfPartialOverlap() {
        let g = geo(40, start: 10, width: 800)   // shows 10…30s
        XCTAssertTrue(g.isVisible(start: 5, duration: 10))    // straddles the left edge
        XCTAssertTrue(g.isVisible(start: 25, duration: 10))   // straddles the right edge
        XCTAssertTrue(g.isVisible(start: 12, duration: 1))    // fully inside
        XCTAssertFalse(g.isVisible(start: 0, duration: 5))    // ends before
        XCTAssertFalse(g.isVisible(start: 40, duration: 5))   // starts after
    }

    func testInitClampsPointsPerSecond() {
        XCTAssertEqual(TimelineGeometry(pointsPerSecond: -5).pointsPerSecond,
                       TimelineGeometry.minPointsPerSecond)
    }
}
