import XCTest
@testable import DesignScaffoldCalendar

final class MonthLayoutTests: XCTestCase {

    /// Deterministic Gregorian/UTC/POSIX calendar so tests don't depend on the
    /// machine's locale or time zone.
    private func config(firstWeekday: Weekday = .sunday) -> CalendarConfiguration {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return CalendarConfiguration(
            calendar: calendar,
            locale: Locale(identifier: "en_US_POSIX"),
            firstWeekday: firstWeekday
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year; components.month = month; components.day = day
        components.timeZone = TimeZone(identifier: "UTC")!
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    func testGridIsAlwaysSixBySeven() {
        let layout = MonthLayout(containing: date(2026, 6, 15), configuration: config())
        XCTAssertEqual(layout.weeks.count, 6)
        XCTAssertTrue(layout.weeks.allSatisfy { $0.count == 7 })
        XCTAssertEqual(layout.allDays.count, 42)
        XCTAssertEqual(layout.weekNumbers.count, 6)
    }

    func testMonthStartIsFirstOfMonth() {
        let layout = MonthLayout(containing: date(2026, 6, 15), configuration: config())
        XCTAssertEqual(layout.monthStart, date(2026, 6, 1))
    }

    func testFebruary2026StartsOnSundayWithSundayFirst() {
        // 1 Feb 2026 is a Sunday, so with a Sunday-first week there are no
        // leading days and the grid's first cell is the 1st.
        let layout = MonthLayout(containing: date(2026, 2, 10), configuration: config(firstWeekday: .sunday))
        XCTAssertEqual(layout.weeks[0][0].date, date(2026, 2, 1))
        XCTAssertTrue(layout.weeks[0][0].isWithinDisplayedMonth)
    }

    func testMondayFirstShiftsLeadingDays() {
        // With a Monday-first week, 1 Feb 2026 (Sunday) sits in the last column,
        // so the grid begins on Mon 26 Jan.
        let layout = MonthLayout(containing: date(2026, 2, 10), configuration: config(firstWeekday: .monday))
        XCTAssertEqual(layout.orderedWeekdays.first, .monday)
        XCTAssertEqual(layout.weeks[0][0].date, date(2026, 1, 26))
        XCTAssertFalse(layout.weeks[0][0].isWithinDisplayedMonth)
        XCTAssertEqual(layout.weeks[0][6].date, date(2026, 2, 1))
    }

    func testInMonthCountMatchesDaysInMonth() {
        // February 2026 has 28 days (not a leap year).
        let layout = MonthLayout(containing: date(2026, 2, 10), configuration: config())
        XCTAssertEqual(layout.allDays.filter { $0.isWithinDisplayedMonth }.count, 28)
    }

    func testOrderedWeekdaysHasSevenUnique() {
        let layout = MonthLayout(containing: date(2026, 6, 1), configuration: config(firstWeekday: .saturday))
        XCTAssertEqual(layout.orderedWeekdays.count, 7)
        XCTAssertEqual(Set(layout.orderedWeekdays).count, 7)
        XCTAssertEqual(layout.orderedWeekdays.first, .saturday)
    }
}
