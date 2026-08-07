import Foundation

/// A single cell in a month grid.
///
/// `date` is always normalised to the start of the day in the configured
/// calendar/time zone, so it is safe to compare or use as an identity.
public struct CalendarDay: Identifiable, Hashable, Sendable {
    /// Start-of-day for this cell.
    public let date: Date
    /// `true` when this day belongs to the month currently being displayed,
    /// `false` for the leading/trailing days borrowed from adjacent months.
    public let isWithinDisplayedMonth: Bool

    public var id: Date { date }

    public init(date: Date, isWithinDisplayedMonth: Bool) {
        self.date = date
        self.isWithinDisplayedMonth = isWithinDisplayedMonth
    }
}
