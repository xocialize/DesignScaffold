import Foundation

/// Pure, deterministic geometry of a single month: a stable 6×7 grid of days
/// (including leading/trailing days from neighbouring months), the matching week
/// numbers, and the weekday ordering for the header. Holds no view state.
public struct MonthLayout: Sendable, Equatable {
    /// Start-of-day of the first day of the displayed month.
    public let monthStart: Date
    /// Six rows of seven days each. Always 6×7 for a stable, non-jumping layout.
    public let weeks: [[CalendarDay]]
    /// ISO week-of-year for each of the six rows.
    public let weekNumbers: [Int]
    /// Weekdays in display order, starting at `configuration.firstWeekday`.
    public let orderedWeekdays: [Weekday]

    /// Builds the layout for the month containing `date`.
    public init(containing date: Date, configuration: CalendarConfiguration) {
        let calendar = configuration.resolvedCalendar

        let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) ?? calendar.startOfDay(for: date)
        self.monthStart = monthStart

        let firstWeekday = configuration.firstWeekday.calendarValue
        let monthStartWeekday = calendar.component(.weekday, from: monthStart)
        let leadingDays = (monthStartWeekday - firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart

        var weeks: [[CalendarDay]] = []
        var weekNumbers: [Int] = []
        weeks.reserveCapacity(6)
        weekNumbers.reserveCapacity(6)

        for row in 0..<6 {
            var week: [CalendarDay] = []
            week.reserveCapacity(7)
            for column in 0..<7 {
                let offset = row * 7 + column
                let rawDate = calendar.date(byAdding: .day, value: offset, to: gridStart) ?? gridStart
                let day = calendar.startOfDay(for: rawDate)
                let inMonth = calendar.isDate(day, equalTo: monthStart, toGranularity: .month)
                week.append(CalendarDay(date: day, isWithinDisplayedMonth: inMonth))
            }
            weeks.append(week)
            weekNumbers.append(calendar.component(.weekOfYear, from: week[0].date))
        }
        self.weeks = weeks
        self.weekNumbers = weekNumbers

        var ordered: [Weekday] = []
        ordered.reserveCapacity(7)
        for i in 0..<7 {
            let raw = ((firstWeekday - 1 + i) % 7) + 1
            if let weekday = Weekday(rawValue: raw) { ordered.append(weekday) }
        }
        self.orderedWeekdays = ordered
    }

    /// Flat list of all 42 cells, row-major.
    public var allDays: [CalendarDay] { weeks.flatMap { $0 } }
}
