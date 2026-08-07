import Foundation

/// A day of the week, backed by the same integer values Foundation's `Calendar`
/// uses for its `.weekday` component (Sunday = 1 ... Saturday = 7).
public enum Weekday: Int, CaseIterable, Sendable, Hashable, Codable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    /// The value as understood by `Calendar` (`firstWeekday`, `.weekday` component).
    public var calendarValue: Int { rawValue }

    /// Convenience set of the two conventional weekend days.
    public static var weekend: Set<Weekday> { [.saturday, .sunday] }
}
