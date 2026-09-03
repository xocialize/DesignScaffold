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
    /// Every DOT-drawn status has its own colour. `attention` is excluded on purpose: it
    /// shares `working`'s amber and is told apart by shape — see the test below.
    func testEveryDotStatusResolvesADistinctColor() {
        let theme = StatusPillTheme.scaffold
        let dots: [Status] = [.idle, .working(), .degraded, .ready, .failed]
        let colors = dots.map { theme.color(for: $0) }
        XCTAssertEqual(Set(colors.map(String.init(describing:))).count, dots.count)
    }

    /// ⚠️ `attention` is the one status a still screenshot must separate from `working` by
    /// SHAPE: it is the only one that draws a glyph instead of a dot. If a second glyph status
    /// ever appears, this test is the place that says two badges now need telling apart.
    func testAttentionIsTheOnlyStatusDrawnAsAGlyph() {
        let theme = StatusPillTheme.scaffold
        XCTAssertNotNil(theme.symbol(for: .attention))
        for other in [Status.idle, .working(), .degraded, .ready, .failed] {
            XCTAssertNil(theme.symbol(for: other), "\(other) must stay a dot")
        }
    }

    /// Settled and waiting on a person: a pulse would say "hold on" to the one party who is
    /// supposed to act. Audio8 mapped needs-folder/needs-download to `.working()` for want of
    /// this case, and breathed at the user indefinitely.
    func testAttentionDoesNotPulse() {
        XCTAssertFalse(Status.attention.pulses)
        XCTAssertNil(Status.attention.elapsed)
    }

    /// ⚠️ `degraded` must not borrow `working`'s orange. The pulse is not enough to separate
    /// them: a still screenshot, a support ticket and a glance all lose it, and those are
    /// exactly the situations where "is this working or broken?" gets asked.
    func testDegradedDoesNotShareWorkingsColour() {
        let theme = StatusPillTheme.scaffold
        XCTAssertNotEqual(String(describing: theme.color(for: .degraded)),
                          String(describing: theme.color(for: .working())))
    }

    /// Degraded is a SETTLED state — the system has arrived somewhere worse, it is not
    /// working toward anything. A pulse would say "hold on".
    func testDegradedDoesNotPulse() {
        XCTAssertFalse(Status.degraded.pulses)
        XCTAssertNil(Status.degraded.elapsed)
        XCTAssertTrue(Status.working().pulses)
    }

    /// The fleet's one rhythm. If these drift apart again, a pulsing dot and a pulsing stepper
    /// ring breathe out of step in two windows at once.
    func testPulseMatchesTheStepper() {
        XCTAssertEqual(StatusPillTheme.scaffold.pulseDuration, Tokens.Motion.pulseDuration)
        XCTAssertEqual(StatusPillTheme.scaffold.pulseMinOpacity, Tokens.Motion.pulseMinOpacity)
    }
}
