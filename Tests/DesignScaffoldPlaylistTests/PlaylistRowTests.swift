import XCTest
@testable import DesignScaffoldPlaylist

/// The pure halves of AB-A-0045: what a row STATE means for rendering, and what an ACTION
/// resolves to. The rendering itself is verified in the Component Lab; these pin the rules
/// the rendering reads from.
final class PlaylistRowTests: XCTestCase {

    // MARK: State → treatment

    func testNormalIsNeitherDimmedNorStruck() {
        XCTAssertFalse(PlaylistRowState.normal.isDimmed)
        XCTAssertFalse(PlaylistRowState.normal.isStruck)
        XCTAssertNil(PlaylistRowState.normal.reason)
        XCTAssertNil(PlaylistRowState.normal.accessibilityPrefix)
    }

    func testUnavailableDimsButDoesNotStrike() {
        let s = PlaylistRowState.unavailable(reason: "no file for landscape")
        XCTAssertTrue(s.isDimmed)
        XCTAssertFalse(s.isStruck)
        XCTAssertEqual(s.reason, "no file for landscape")
    }

    /// Disabled is the STRONGER state: dimmed AND struck. A skipped row must read as
    /// authored-out, not merely absent.
    func testDisabledDimsAndStrikes() {
        let s = PlaylistRowState.disabled(reason: "skip flag")
        XCTAssertTrue(s.isDimmed)
        XCTAssertTrue(s.isStruck)
    }

    /// VoiceOver hears WHY, not just that the text is grey. And a state with no reason still
    /// announces itself rather than staying silent.
    func testAccessibilityPrefixCarriesTheReasonOrJustTheState() {
        XCTAssertEqual(PlaylistRowState.unavailable(reason: "missing").accessibilityPrefix,
                       "unavailable, missing")
        XCTAssertEqual(PlaylistRowState.unavailable().accessibilityPrefix, "unavailable")
        XCTAssertEqual(PlaylistRowState.disabled(reason: "authored skip").accessibilityPrefix,
                       "skipped, authored skip")
        XCTAssertEqual(PlaylistRowState.disabled().accessibilityPrefix, "skipped")
    }

    // MARK: Action → symbol

    func testPlainActionAlwaysDrawsItsSymbol() {
        let a = PlaylistRowAction.action("Export", symbol: "square.and.arrow.up") {}
        XCTAssertEqual(a.resolvedSymbol, "square.and.arrow.up")
        XCTAssertFalse(a.isToggledOn)
        XCTAssertEqual(a.role, .normal)
    }

    /// The `.fill` convention: `star` → `star.fill` when on, with no second symbol supplied.
    /// This is exactly what ML[X] Audio Studio's favourite did by hand.
    func testToggleFollowsTheFillConventionWhenOn() {
        let off = PlaylistRowAction.toggle("Favourite", symbol: "star", isOn: false) {}
        let on = PlaylistRowAction.toggle("Favourite", symbol: "star", isOn: true) {}
        XCTAssertEqual(off.resolvedSymbol, "star")
        XCTAssertEqual(on.resolvedSymbol, "star.fill")
        XCTAssertTrue(on.isToggledOn)
        XCTAssertFalse(off.isToggledOn)
    }

    func testAnExplicitOnSymbolWinsOverTheConvention() {
        let on = PlaylistRowAction.toggle("Lock", symbol: "lock.open", onSymbol: "lock",
                                          isOn: true) {}
        XCTAssertEqual(on.resolvedSymbol, "lock")
    }

    // MARK: Action → symbol that is actually DRAWN (AB-A-0058)

    /// ⚠️ `repeat.1.fill` does not exist. SwiftUI draws nothing for it and says nothing —
    /// MarqueeStudio's loop toggle vanished when on. The drawn symbol must fall back to the
    /// base one, so the worst case is a toggle that reads by tint alone.
    func testAMissingFillFallsBackToTheBaseSymbol() {
        let on = PlaylistRowAction.toggle("Loop", symbol: "repeat.1", isOn: true) {}
        XCTAssertEqual(on.resolvedSymbol, "repeat.1.fill", "the INTENT is still the fill")
        XCTAssertEqual(on.drawableSymbol(exists: { $0 != "repeat.1.fill" }), "repeat.1")
    }

    func testAnExistingFillIsDrawnAsIntended() {
        let on = PlaylistRowAction.toggle("Favourite", symbol: "star", isOn: true) {}
        XCTAssertEqual(on.drawableSymbol(exists: { _ in true }), "star.fill")
    }

    /// An explicit `onSymbol` gets the same protection — a typo there would vanish too.
    func testAMissingExplicitOnSymbolAlsoFallsBack() {
        let on = PlaylistRowAction.toggle("Lock", symbol: "lock.open", onSymbol: "lokc",
                                          isOn: true) {}
        XCTAssertEqual(on.drawableSymbol(exists: { $0 != "lokc" }), "lock.open")
    }

    /// Off toggles and plain actions draw the host's own symbol without consulting anything:
    /// there is nothing better to fall back to, and a wrong base name is the host's bug.
    func testOffAndPlainNeverConsultTheCatalog() {
        var consulted = 0
        let off = PlaylistRowAction.toggle("Loop", symbol: "repeat.1", isOn: false) {}
        let plain = PlaylistRowAction.action("Export", symbol: "square.and.arrow.up") {}
        XCTAssertEqual(off.drawableSymbol(exists: { _ in consulted += 1; return false }), "repeat.1")
        XCTAssertEqual(plain.drawableSymbol(exists: { _ in consulted += 1; return false }),
                       "square.and.arrow.up")
        XCTAssertEqual(consulted, 0)
    }

    /// The real catalog, on the real platform: the two Marquee hit, one that exists, and a
    /// control that cannot. If `repeat.1.fill` ever ships in SF Symbols this test will say so,
    /// which is fine — the fallback simply stops being exercised.
    func testTheCatalogKnowsWhichFillsAreReal() {
        XCTAssertFalse(SymbolCatalog.exists("repeat.1.fill"))
        XCTAssertFalse(SymbolCatalog.exists("arrow.right.to.line.fill"))
        XCTAssertTrue(SymbolCatalog.exists("pause.circle.fill"))
        XCTAssertTrue(SymbolCatalog.exists("star.fill"))
        XCTAssertFalse(SymbolCatalog.exists("definitely.not.a.symbol"))
    }

    func testDestructiveCarriesItsRole() {
        let d = PlaylistRowAction.destructive("Delete", symbol: "trash") {}
        XCTAssertEqual(d.role, .destructive)
        XCTAssertFalse(d.isToggledOn)
    }

    /// `id` defaults to the label, so two rows' "Favourite" buttons collide only within a
    /// row — which is the scope `ForEach` cares about.
    func testIdDefaultsToLabelAndCanBeOverridden() {
        XCTAssertEqual(PlaylistRowAction.action("Export", symbol: "x") {}.id, "Export")
        XCTAssertEqual(PlaylistRowAction.action("Export", symbol: "x", id: "exp") {}.id, "exp")
    }

    // MARK: Theme

    /// The three tints are distinct: an ON toggle, a destructive action, and everything else
    /// must not collapse into one colour or the column stops saying anything.
    func testActionTintsAreDistinct() {
        let t = PlaylistTheme.scaffold
        let tints = [t.actionTint, t.actionOnTint, t.actionDestructiveTint]
        XCTAssertEqual(Set(tints.map(String.init(describing:))).count, 3)
    }

    /// The dimmed colour must differ from the normal name colour, or "unavailable" is invisible.
    func testDimmedTextDiffersFromNameText() {
        let t = PlaylistTheme.scaffold
        XCTAssertNotEqual(String(describing: t.dimmedText), String(describing: t.nameText))
    }
}
