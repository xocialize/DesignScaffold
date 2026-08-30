import SwiftUI
import XCTest
@testable import DesignScaffold

/// The base product had no test target until `SectionHeader` landed in it — the one module
/// every other product depends on. These are not tests of how things LOOK; they are anchors,
/// asserting that the vocabulary's own pieces keep reading from the vocabulary. That is the
/// exact drift that produced twelve section headers and two pulse rhythms.
final class VocabularyTests: XCTestCase {

    private func describe(_ v: Any) -> String { String(describing: v) }

    // MARK: Section header

    func testSectionHeaderDefaultsComeFromTokens() {
        let t = SectionHeaderTheme.scaffold
        XCTAssertEqual(describe(t.font), describe(Tokens.Font.caption.weight(.semibold)))
        XCTAssertEqual(describe(t.color), describe(Tokens.Color.secondaryLabel))
        XCTAssertEqual(describe(t.trailingColor), describe(Tokens.Color.tertiaryLabel))
    }

    /// The majority of the twelve promoted copies used 0.5; the ModelSheetStudio pair used 0.6.
    /// If this changes it should be a decision, not a copy drifting back in.
    func testSectionHeaderTrackingIsTheMajorityValue() {
        XCTAssertEqual(SectionHeaderTheme.scaffold.tracking, 0.5)
        XCTAssertTrue(SectionHeaderTheme.scaffold.uppercases)
    }

    /// MLXEngineUI's settings panels want the title as typed. A theme, not a fork.
    func testSentenceCaseThemeIsPlain() {
        XCTAssertFalse(SectionHeaderTheme.sentenceCase.uppercases)
        XCTAssertEqual(SectionHeaderTheme.sentenceCase.tracking, 0)
    }

    // MARK: Motion

    /// One rhythm for "work in flight". StatusPill and StageStepper both read these, and they
    /// were 0.6/0.3 against 0.9/0.15 before this token existed.
    func testMotionIsASingleSharedRhythm() {
        XCTAssertEqual(Tokens.Motion.pulseDuration, 0.9)
        XCTAssertEqual(Tokens.Motion.pulseMinOpacity, 0.15)
    }

    /// ⚠️ Not 1.0. A pulsing affordance that cannot breathe must still read as ACTIVE, and a
    /// pulse that simply stops is indistinguishable from one that finished.
    func testReducedMotionOpacityIsNotFull() {
        XCTAssertLessThan(Tokens.Motion.reducedMotionOpacity, 1.0)
        XCTAssertGreaterThan(Tokens.Motion.reducedMotionOpacity, 0.5)
    }

    // MARK: Layout

    /// The comment on this token records why: at 132 two tiles did NOT fit inside
    /// `inspectorWidth` minus padding, and the grid silently fell back to one column.
    func testTwoMetricTilesFitAnInspector() {
        let usable = Tokens.Layout.inspectorWidth - Tokens.Space.m * 2
        XCTAssertGreaterThanOrEqual(usable, Tokens.Layout.metricTileMinWidth * 2 + Tokens.Space.s,
                                    "metricTileMinWidth must keep two tiles in an inspector")
    }

    func testHairlineIsOnePoint() {
        XCTAssertEqual(Tokens.Layout.hairline, 1)
    }

    /// The spacing scale is the 4pt grid. A value off it is how a design starts drifting by eye.
    func testSpacingIsOnTheFourPointGrid() {
        for value in [Tokens.Space.xs, Tokens.Space.s, Tokens.Space.m,
                      Tokens.Space.l, Tokens.Space.xl, Tokens.Space.xxl] {
            XCTAssertEqual(value.truncatingRemainder(dividingBy: 4), 0, "\(value) is off-grid")
        }
    }

    func testSpacingScaleIsStrictlyIncreasing() {
        let scale = [Tokens.Space.xs, Tokens.Space.s, Tokens.Space.m,
                     Tokens.Space.l, Tokens.Space.xl, Tokens.Space.xxl]
        XCTAssertEqual(scale, scale.sorted())
        XCTAssertEqual(Set(scale).count, scale.count, "two names for one size is a coin toss at the call site")
    }
}
