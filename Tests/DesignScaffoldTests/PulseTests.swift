import Foundation
import XCTest
@testable import DesignScaffold

/// The pulse used to be an implicit `repeatForever(autoreverses:)` animation, which meant
/// its behaviour lived entirely inside SwiftUI and **nothing here could have caught the bug
/// it shipped** — a dot that detached from its pill and slid up and down the window,
/// because the repeating animation had captured the view's position along with its opacity.
///
/// Making the pulse a pure function of time is what fixed that, and these tests exist
/// because it is now testable at all. They pin the SHAPE — the thing a future refactor
/// would quietly change — not the rendering.
final class PulseTests: XCTestCase {

    private let duration = 0.9
    private let minOpacity = 0.15

    private func opacity(atPhase phase: Double, active: Bool = true,
                         reduceMotion: Bool = false, maxOpacity: Double = 1) -> Double {
        // A full breath is 2 × duration, so `phase` here is a fraction of that period.
        Pulse.opacity(at: Date(timeIntervalSinceReferenceDate: phase * duration * 2),
                      active: active,
                      reduceMotion: reduceMotion,
                      duration: duration,
                      minOpacity: minOpacity,
                      maxOpacity: maxOpacity,
                      reducedMotionOpacity: Tokens.Motion.reducedMotionOpacity)
    }

    // MARK: The breath

    func testTheBreathStartsFullAndReachesTheFloorHalfWay() {
        XCTAssertEqual(opacity(atPhase: 0), 1, accuracy: 1e-9)
        XCTAssertEqual(opacity(atPhase: 0.5), minOpacity, accuracy: 1e-9)
    }

    /// Out AND back within one period — which is what `autoreverses: true` meant, and the
    /// property most likely to be halved by someone "simplifying" the period arithmetic.
    func testOnePeriodIsOutAndBack() {
        XCTAssertEqual(opacity(atPhase: 0), opacity(atPhase: 1), accuracy: 1e-9)
        XCTAssertEqual(opacity(atPhase: 0.25), opacity(atPhase: 0.75), accuracy: 1e-9)
    }

    func testTheBreathNeverLeavesItsRange() {
        for step in 0...200 {
            let value = opacity(atPhase: Double(step) / 100)
            XCTAssertGreaterThanOrEqual(value, minOpacity - 1e-9)
            XCTAssertLessThanOrEqual(value, 1 + 1e-9)
        }
    }

    func testTheFirstHalfOnlyFades() {
        var previous = opacity(atPhase: 0)
        for step in 1...50 {
            let value = opacity(atPhase: Double(step) / 100)
            XCTAssertLessThanOrEqual(value, previous + 1e-9, "reversed at phase \(step)/100")
            previous = value
        }
    }

    /// Eased at the turning points, not linear — a triangle wave reads as a blink.
    ///
    /// ⚠️ NOT at the quarter phase, which is where the first version of this test looked
    /// and failed: a raised cosine crosses the exact midpoint of its range at the quarter
    /// phase, precisely as a triangle wave does. The two curves are indistinguishable
    /// there. The easing lives either side of it — the cosine LINGERS near each turning
    /// point, so an eighth of the way in it is still brighter than a linear ramp, and
    /// three-eighths in it is already dimmer.
    func testTheTurningPointsAreEasedNotLinear() {
        func triangle(_ phase: Double) -> Double {
            let up = phase <= 0.5 ? phase * 2 : (1 - phase) * 2
            return 1 - up * (1 - minOpacity)
        }
        XCTAssertEqual(opacity(atPhase: 0.25), triangle(0.25), accuracy: 1e-9,
                       "the curves meet at the quarter phase — do not test easing here")
        XCTAssertGreaterThan(opacity(atPhase: 0.125), triangle(0.125) + 1e-6)
        XCTAssertLessThan(opacity(atPhase: 0.375), triangle(0.375) - 1e-6)
    }

    // MARK: What does not breathe

    func testOnlyActiveBreathes() {
        for step in 0...20 {
            XCTAssertEqual(opacity(atPhase: Double(step) / 10, active: false), 1, accuracy: 1e-9)
        }
    }

    /// ⚠️ Steady and slightly faded, NOT full and NOT the floor: it still has to read as
    /// active when it cannot breathe, and a pulse that simply stops is indistinguishable
    /// from one that finished.
    func testReduceMotionHoldsASteadyFadedValue() {
        for step in 0...20 {
            XCTAssertEqual(opacity(atPhase: Double(step) / 10, reduceMotion: true),
                           Tokens.Motion.reducedMotionOpacity, accuracy: 1e-9)
        }
        XCTAssertLessThan(Tokens.Motion.reducedMotionOpacity, 1)
        XCTAssertGreaterThan(Tokens.Motion.reducedMotionOpacity, minOpacity)
    }

    func testTheScheduleOnlyRunsWhenThereIsSomethingToShow() {
        // Paused is not observable on the schedule value, so this pins the decision itself:
        // frames are spent only when active and motion is allowed.
        XCTAssertTrue(Pulse.shouldTick(active: true, reduceMotion: false))
        XCTAssertFalse(Pulse.shouldTick(active: false, reduceMotion: false))
        XCTAssertFalse(Pulse.shouldTick(active: true, reduceMotion: true))
        XCTAssertFalse(Pulse.shouldTick(active: false, reduceMotion: true))
    }

    // MARK: Caller mistakes fail to "no pulse", never to a crash or a flicker

    func testDegenerateInputsDoNotDivideByZero() {
        for bad in [0.0, -1.0] {
            let value = Pulse.opacity(at: Date(timeIntervalSinceReferenceDate: 12.34),
                                      active: true, reduceMotion: false,
                                      duration: bad, minOpacity: minOpacity)
            XCTAssertEqual(value, 1, accuracy: 1e-9)
        }
    }

    func testAnInvertedRangeDoesNotInvertTheBreath() {
        let value = Pulse.opacity(at: Date(timeIntervalSinceReferenceDate: 12.34),
                                  active: true, reduceMotion: false,
                                  duration: duration, minOpacity: 0.8, maxOpacity: 0.2)
        XCTAssertEqual(value, 0.2, accuracy: 1e-9)
    }

    // MARK: The stepper's ring rests under full

    func testMaxOpacityIsHonouredAtBothEnds() {
        XCTAssertEqual(opacity(atPhase: 0, maxOpacity: 0.9), 0.9, accuracy: 1e-9)
        XCTAssertEqual(opacity(atPhase: 0.5, maxOpacity: 0.9), minOpacity, accuracy: 1e-9)
    }
}
