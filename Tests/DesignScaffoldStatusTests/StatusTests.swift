import XCTest
@testable import DesignScaffoldStatus

final class StatusTests: XCTestCase {

    /// Only work in flight breathes. A pulse on a settled state is a lie the user learns to
    /// ignore, which costs the pulse its meaning everywhere else.
    func testOnlyWorkingPulses() {
        XCTAssertTrue(Status.working().pulses)
        XCTAssertTrue(Status.working(elapsed: 3).pulses)
        XCTAssertFalse(Status.idle.pulses)
        XCTAssertFalse(Status.ready.pulses)
        XCTAssertFalse(Status.failed.pulses)
    }

    func testElapsedIsOnlyCarriedByWorking() {
        XCTAssertEqual(Status.working(elapsed: 12.34).elapsed, 12.34)
        XCTAssertNil(Status.working().elapsed)
        XCTAssertNil(Status.ready.elapsed)
    }

    func testElapsedFormatIsOneDecimal() {
        XCTAssertEqual(StatusFormat.elapsed(12.34), "12.3 s")
        XCTAssertEqual(StatusFormat.elapsed(0), "0.0 s")
    }

    /// A clock that has not started, or a host subtracting timestamps across a pause, can hand
    /// this a negative. "-0.4 s elapsed" reads as a broken app.
    func testNegativeElapsedIsClamped() {
        XCTAssertEqual(StatusFormat.elapsed(-0.4), "0.0 s")
    }

    /// `.working()` and `.working(elapsed:)` are different states, so a pill bound to a
    /// changing value re-renders when the seconds tick.
    func testEqualityDistinguishesElapsed() {
        XCTAssertNotEqual(Status.working(elapsed: 1), Status.working(elapsed: 2))
        XCTAssertEqual(Status.working(elapsed: 1), Status.working(elapsed: 1))
        XCTAssertNotEqual(Status.working(), Status.working(elapsed: 0))
    }

    /// The dot colour comes from the status, never from the call site — the reason four of the
    /// eight promoted copies needed replacing.
    func testEveryStatusResolvesADistinctColor() {
        let theme = StatusPillTheme.scaffold
        let colors = [Status.idle, .working(), .ready, .failed].map { theme.color(for: $0) }
        XCTAssertEqual(Set(colors.map(String.init(describing:))).count, 4)
    }

    /// The fleet's one rhythm. If these drift apart again, a pulsing dot and a pulsing stepper
    /// ring breathe out of step in two windows at once.
    func testPulseMatchesTheStepper() {
        XCTAssertEqual(StatusPillTheme.scaffold.pulseDuration, Tokens.Motion.pulseDuration)
        XCTAssertEqual(StatusPillTheme.scaffold.pulseMinOpacity, Tokens.Motion.pulseMinOpacity)
    }
}
