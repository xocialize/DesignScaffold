import SwiftUI

/// Chainable configuration. Each modifier returns a copy of the view with one
/// piece of ``CalendarConfiguration`` (or the theme) changed, so calls read
/// naturally: `CalendarView(selection: $d).firstWeekday(.monday).showsWeekNumbers()`.
public extension CalendarView {

    /// Override the visual theme. Without this, ``CalendarTheme/scaffold`` is used.
    func theme(_ theme: CalendarTheme) -> CalendarView {
        var copy = self
        copy.themeOverride = theme
        return copy
    }

    /// Replace the whole configuration.
    func configuration(_ configuration: CalendarConfiguration) -> CalendarView {
        var copy = self
        copy.configuration = configuration
        return copy
    }

    /// The day the week grid starts on.
    func firstWeekday(_ weekday: Weekday) -> CalendarView {
        var copy = self
        copy.configuration.firstWeekday = weekday
        return copy
    }

    /// The locale used for month titles and weekday symbols.
    func locale(_ locale: Locale) -> CalendarView {
        var copy = self
        copy.configuration.locale = locale
        return copy
    }

    /// The calendar used for all date math.
    func calendar(_ calendar: Calendar) -> CalendarView {
        var copy = self
        copy.configuration.calendar = calendar
        return copy
    }

    /// Restrict the selectable range. Pass `nil` for an open bound.
    func bounds(minimum: Date? = nil, maximum: Date? = nil) -> CalendarView {
        var copy = self
        copy.configuration.minimumDate = minimum
        copy.configuration.maximumDate = maximum
        return copy
    }

    /// Weekdays that cannot be selected.
    func disabledWeekdays(_ weekdays: Set<Weekday>) -> CalendarView {
        var copy = self
        copy.configuration.disabledWeekdays = weekdays
        return copy
    }

    /// Weekdays rendered in the theme's weekend colour (styling only).
    func weekendDays(_ weekdays: Set<Weekday>) -> CalendarView {
        var copy = self
        copy.configuration.weekendDays = weekdays
        return copy
    }

    /// Disable arbitrary days via a predicate (e.g. holidays).
    func disabledDates(_ predicate: @escaping @Sendable (Date) -> Bool) -> CalendarView {
        var copy = self
        copy.configuration.isDateDisabled = predicate
        return copy
    }

    /// Show or hide the leading week-number column.
    func showsWeekNumbers(_ shows: Bool = true) -> CalendarView {
        var copy = self
        copy.configuration.showsWeekNumbers = shows
        return copy
    }

    /// Show or hide the "Today" shortcut in the header.
    func showsTodayButton(_ shows: Bool = true) -> CalendarView {
        var copy = self
        copy.configuration.showsTodayButton = shows
        return copy
    }
}
