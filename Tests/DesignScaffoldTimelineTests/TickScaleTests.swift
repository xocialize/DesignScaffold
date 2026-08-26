import XCTest
@testable import DesignScaffoldTimeline

final class TickScaleTests: XCTestCase {

    func testIntervalStepsUpAsZoomDecreases() {
        // Labels need >= 56pt of room.
        let zoomedIn = TickScale.interval(pointsPerSecond: 400, minSpacing: 56)
        let mid = TickScale.interval(pointsPerSecond: 40, minSpacing: 56)
        let zoomedOut = TickScale.interval(pointsPerSecond: 2, minSpacing: 56)
        XCTAssertLessThan(zoomedIn, mid)
        XCTAssertLessThan(mid, zoomedOut)
    }

    func testChosenIntervalAlwaysClearsMinimumSpacing() {
        for pps in stride(from: CGFloat(1), through: 800, by: 7) {
            let interval = TickScale.interval(pointsPerSecond: pps, minSpacing: 56)
            // Either it clears the bar, or it is the coarsest rung we have.
            let spacing = CGFloat(interval) * pps
            XCTAssertTrue(spacing >= 56 || interval == TickScale.ladder.last!,
                          "pps \(pps) chose \(interval) → \(spacing)pt")
        }
    }

    func testEveryIntervalIsAReadableRung() {
        let interval = TickScale.interval(pointsPerSecond: 37, minSpacing: 56)
        XCTAssertTrue(TickScale.ladder.contains(interval))
    }

    /// Ticks align to round times, not to wherever the scroll happens to sit.
    func testTicksAlignToWholeMultiples() {
        XCTAssertEqual(TickScale.ticks(in: 7.3...20, interval: 5), [5, 10, 15, 20])
    }

    /// The tick at or before the left edge is ALWAYS included — its label is drawn to its
    /// right, so it can still be on screen. Admitting it conditionally (an earlier version
    /// used a half-interval tolerance) made the leading label blink in and out as the
    /// scroll moved within one interval.
    func testStraddlingLeadingTickIsAlwaysIncluded() {
        for lower in stride(from: 7.0, through: 9.9, by: 0.3) {
            XCTAssertEqual(TickScale.ticks(in: lower...20, interval: 5).first, 5,
                           "lower \(lower) dropped the straddling tick")
        }
    }

    func testTicksIncludeAnAlignedLeadingEdge() {
        XCTAssertEqual(TickScale.ticks(in: 10...20, interval: 5).first, 10)
    }

    /// A zero/negative interval must yield nothing rather than spinning. (An *inverted*
    /// range is not testable — `ClosedRange` traps at construction, which is why
    /// `ticks(in:)` carries no guard for it.)
    func testNonPositiveIntervalIsEmptyNotInfinite() {
        XCTAssertTrue(TickScale.ticks(in: 0...10, interval: 0).isEmpty)
        XCTAssertTrue(TickScale.ticks(in: 0...10, interval: -1).isEmpty)
    }

    func testTickCountIsBounded() {
        XCTAssertLessThanOrEqual(TickScale.ticks(in: 0...1_000_000, interval: 0.1).count, 512)
    }
}
