import XCTest
@testable import DesignScaffoldCalendar

final class SelectionEngineTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year; components.month = month; components.day = day
        components.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: components)!
    }

    // MARK: Single

    func testSingleState() {
        let selected = date(2026, 6, 10)
        XCTAssertEqual(SelectionEngine.singleState(day: selected, selection: selected, calendar: calendar), .selected)
        XCTAssertEqual(SelectionEngine.singleState(day: date(2026, 6, 11), selection: selected, calendar: calendar), .none)
        XCTAssertEqual(SelectionEngine.singleState(day: selected, selection: nil, calendar: calendar), .none)
    }

    func testSingleStateIgnoresTimeOfDay() {
        // Same calendar day, different clock time, should still match.
        let selected = date(2026, 6, 10).addingTimeInterval(3600 * 9)
        XCTAssertEqual(SelectionEngine.singleState(day: date(2026, 6, 10), selection: selected, calendar: calendar), .selected)
    }

    // MARK: Multiple

    func testToggleAddsAndRemoves() {
        var selection: [Date] = []
        selection = SelectionEngine.toggle(day: date(2026, 6, 10), in: selection, calendar: calendar)
        selection = SelectionEngine.toggle(day: date(2026, 6, 12), in: selection, calendar: calendar)
        XCTAssertEqual(selection.count, 2)
        XCTAssertEqual(SelectionEngine.multipleState(day: date(2026, 6, 10), selection: selection, calendar: calendar), .selected)

        // Toggling an existing day removes it.
        selection = SelectionEngine.toggle(day: date(2026, 6, 10), in: selection, calendar: calendar)
        XCTAssertEqual(selection.count, 1)
        XCTAssertEqual(SelectionEngine.multipleState(day: date(2026, 6, 10), selection: selection, calendar: calendar), .none)
    }

    func testToggleKeepsSelectionSorted() {
        var selection: [Date] = []
        selection = SelectionEngine.toggle(day: date(2026, 6, 20), in: selection, calendar: calendar)
        selection = SelectionEngine.toggle(day: date(2026, 6, 5), in: selection, calendar: calendar)
        XCTAssertEqual(selection, [date(2026, 6, 5), date(2026, 6, 20)])
    }

    // MARK: Range

    func testRangeTapSetsAnchorThenCompletes() {
        let first = SelectionEngine.rangeTap(day: date(2026, 6, 10), anchor: nil, calendar: calendar)
        XCTAssertEqual(first.anchor, date(2026, 6, 10))
        XCTAssertNil(first.range)

        let second = SelectionEngine.rangeTap(day: date(2026, 6, 15), anchor: first.anchor, calendar: calendar)
        XCTAssertNil(second.anchor)
        XCTAssertEqual(second.range, date(2026, 6, 10)...date(2026, 6, 15))
    }

    func testRangeTapNormalisesReversedOrder() {
        // Tapping a later day first, then an earlier one, still yields lower...upper.
        let anchor = SelectionEngine.rangeTap(day: date(2026, 6, 20), anchor: nil, calendar: calendar).anchor
        let result = SelectionEngine.rangeTap(day: date(2026, 6, 5), anchor: anchor, calendar: calendar)
        XCTAssertEqual(result.range, date(2026, 6, 5)...date(2026, 6, 20))
    }

    func testRangeStateClassifiesBoundsAndInterior() {
        let range = date(2026, 6, 10)...date(2026, 6, 15)
        XCTAssertEqual(SelectionEngine.rangeState(day: date(2026, 6, 10), range: range, anchor: nil, calendar: calendar), .rangeStart)
        XCTAssertEqual(SelectionEngine.rangeState(day: date(2026, 6, 15), range: range, anchor: nil, calendar: calendar), .rangeEnd)
        XCTAssertEqual(SelectionEngine.rangeState(day: date(2026, 6, 12), range: range, anchor: nil, calendar: calendar), .inRange)
        XCTAssertEqual(SelectionEngine.rangeState(day: date(2026, 6, 9), range: range, anchor: nil, calendar: calendar), .none)
    }

    func testRangeStateSingleDayRangeIsSelected() {
        let range = date(2026, 6, 10)...date(2026, 6, 10)
        XCTAssertEqual(SelectionEngine.rangeState(day: date(2026, 6, 10), range: range, anchor: nil, calendar: calendar), .selected)
    }

    func testRangeStatePendingAnchorShowsSelected() {
        let anchor = date(2026, 6, 10)
        XCTAssertEqual(SelectionEngine.rangeState(day: anchor, range: nil, anchor: anchor, calendar: calendar), .selected)
        XCTAssertEqual(SelectionEngine.rangeState(day: date(2026, 6, 11), range: nil, anchor: anchor, calendar: calendar), .none)
    }
}
