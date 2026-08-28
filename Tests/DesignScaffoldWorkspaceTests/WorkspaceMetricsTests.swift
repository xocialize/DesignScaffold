import XCTest
@testable import DesignScaffoldWorkspace

/// The narrow-window behaviour is the whole reason this arithmetic is not inline: it is
/// invisible until someone drags a window, and wrong in every hand-rolled shell it replaces.
final class WorkspaceMetricsTests: XCTestCase {

    func testRoomForEveryone() {
        let r = WorkspaceMetrics.resolve(available: 1400, leading: 350, trailing: 300,
                                         centerMinimum: 320)
        XCTAssertEqual(r.leading, 350)
        XCTAssertEqual(r.trailing, 300)
        XCTAssertEqual(r.center, 750)
    }

    func testWidthsAlwaysSumToAvailable() {
        for width in stride(from: CGFloat(0), through: 2000, by: 37) {
            let r = WorkspaceMetrics.resolve(available: width, leading: 350, trailing: 300,
                                             centerMinimum: 320)
            XCTAssertEqual(r.leading + r.center + r.trailing, width, accuracy: 0.001,
                           "panes must tile the available width exactly at \(width)")
        }
    }

    /// The bug this exists to prevent: the work area is NOT what gives way first.
    func testTheCenterKeepsItsMinimumUntilBothPanesAreGone() {
        let r = WorkspaceMetrics.resolve(available: 800, leading: 350, trailing: 300,
                                         centerMinimum: 320)
        XCTAssertGreaterThanOrEqual(r.center, 320)
        XCTAssertEqual(r.leading, 350, "the rail holds while the inspector still has width")
        XCTAssertEqual(r.trailing, 130, "the inspector yields first")
    }

    func testTheInspectorGoesBeforeTheRail() {
        let r = WorkspaceMetrics.resolve(available: 600, leading: 350, trailing: 300,
                                         centerMinimum: 320)
        XCTAssertEqual(r.trailing, 0)
        XCTAssertEqual(r.leading, 280)
        XCTAssertEqual(r.center, 320)
    }

    /// Past the point where even collapsing both panes is not enough, the center takes what
    /// is left rather than the layout going negative.
    func testBelowEverythingTheCenterTakesTheRemainder() {
        let r = WorkspaceMetrics.resolve(available: 200, leading: 350, trailing: 300,
                                         centerMinimum: 320)
        XCTAssertEqual(r.leading, 0)
        XCTAssertEqual(r.trailing, 0)
        XCTAssertEqual(r.center, 200)
    }

    func testTwoPaneLayoutIgnoresTheTrailingWidth() {
        let r = WorkspaceMetrics.resolve(available: 900, leading: 260, trailing: 0,
                                         centerMinimum: 320)
        XCTAssertEqual(r.leading, 260)
        XCTAssertEqual(r.center, 640)
        XCTAssertEqual(r.trailing, 0)
    }

    func testNegativeAndZeroInputsDoNotProduceNegativeWidths() {
        let r = WorkspaceMetrics.resolve(available: -50, leading: -10, trailing: -10,
                                         centerMinimum: -10)
        XCTAssertEqual(r, .init(leading: 0, center: 0, trailing: 0))
    }
}
