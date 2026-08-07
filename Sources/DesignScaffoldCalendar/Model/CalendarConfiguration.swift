import Foundation

/// All non-visual behaviour of a ``CalendarView``: which calendar/locale to use,
/// where the week starts, date bounds, and which days are disabled or treated as
/// weekends. Visual styling lives in ``CalendarTheme`` instead.
public struct CalendarConfiguration: Sendable {

    /// The calendar used for all date math. Its time zone is honoured.
    public var calendar: Calendar
    /// The locale used for month titles and weekday symbols.
    public var locale: Locale
    /// The day the week grid starts on.
    public var firstWeekday: Weekday
    /// Earliest selectable day (inclusive). Days before this are disabled.
    public var minimumDate: Date?
    /// Latest selectable day (inclusive). Days after this are disabled.
    public var maximumDate: Date?
    /// Weekdays that cannot be selected at all.
    public var disabledWeekdays: Set<Weekday>
    /// Weekdays rendered with the theme's weekend colour (styling only).
    public var weekendDays: Set<Weekday>
    /// Show the ISO week-of-year column on the leading edge.
    public var showsWeekNumbers: Bool
    /// Show the "Today" shortcut button in the header.
    public var showsTodayButton: Bool
    /// Optional predicate to disable arbitrary days (e.g. holidays).
    public var isDateDisabled: (@Sendable (Date) -> Bool)?

    public init(
        calendar: Calendar = .current,
        locale: Locale = .current,
        firstWeekday: Weekday = .sunday,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        disabledWeekdays: Set<Weekday> = [],
        weekendDays: Set<Weekday> = Weekday.weekend,
        showsWeekNumbers: Bool = false,
        showsTodayButton: Bool = true,
        isDateDisabled: (@Sendable (Date) -> Bool)? = nil
    ) {
        self.calendar = calendar
        self.locale = locale
        self.firstWeekday = firstWeekday
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.disabledWeekdays = disabledWeekdays
        self.weekendDays = weekendDays
        self.showsWeekNumbers = showsWeekNumbers
        self.showsTodayButton = showsTodayButton
        self.isDateDisabled = isDateDisabled
    }

    /// A calendar with the configuration's locale and first-weekday applied.
    /// All internal date math goes through this so the two stay in sync.
    public var resolvedCalendar: Calendar {
        var c = calendar
        c.locale = locale
        c.firstWeekday = firstWeekday.calendarValue
        return c
    }

    /// Whether the given day cannot be selected, accounting for bounds,
    /// disabled weekdays, and the custom predicate.
    public func isDisabled(_ date: Date) -> Bool {
        let cal = resolvedCalendar
        let day = cal.startOfDay(for: date)
        if let min = minimumDate, day < cal.startOfDay(for: min) { return true }
        if let max = maximumDate, day > cal.startOfDay(for: max) { return true }
        if let weekday = Weekday(rawValue: cal.component(.weekday, from: day)),
           disabledWeekdays.contains(weekday) {
            return true
        }
        if let predicate = isDateDisabled, predicate(day) { return true }
        return false
    }

    /// Whether the given day falls on a styling weekend.
    public func isWeekend(_ date: Date) -> Bool {
        guard let weekday = Weekday(rawValue: resolvedCalendar.component(.weekday, from: date)) else {
            return false
        }
        return weekendDays.contains(weekday)
    }

    // MARK: Localised text

    /// Localised "Month Year" title (e.g. "June 2026").
    public func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = resolvedCalendar
        formatter.locale = locale
        formatter.timeZone = resolvedCalendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: date)
    }

    /// Short localised symbol for a weekday (e.g. "Mon").
    public func shortSymbol(for weekday: Weekday) -> String {
        let formatter = DateFormatter()
        formatter.calendar = resolvedCalendar
        formatter.locale = locale
        let symbols = formatter.shortStandaloneWeekdaySymbols ?? formatter.shortWeekdaySymbols ?? []
        let index = weekday.rawValue - 1
        return symbols.indices.contains(index) ? symbols[index] : ""
    }

    /// Full localised, accessible description of a day (e.g. "Monday, June 29, 2026").
    public func accessibilityLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = resolvedCalendar
        formatter.locale = locale
        formatter.timeZone = resolvedCalendar.timeZone
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// The day-of-month number as a localised string (e.g. "29").
    public func dayNumber(for date: Date) -> String {
        let number = resolvedCalendar.component(.day, from: date)
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .none
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
