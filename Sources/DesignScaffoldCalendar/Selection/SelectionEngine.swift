import Foundation

/// How a given day participates in the current selection. Drives styling in the
/// day cell.
public enum DaySelectionState: Equatable, Sendable {
    /// Not part of the selection.
    case none
    /// Selected (single mode, a member of a multiple selection, or a single-day range).
    case selected
    /// The lower bound of a multi-day range.
    case rangeStart
    /// The upper bound of a multi-day range.
    case rangeEnd
    /// Strictly between the bounds of a range.
    case inRange
}

/// Pure selection logic, kept separate from SwiftUI so it can be unit-tested
/// headlessly. Every function normalises to start-of-day in the supplied calendar.
public enum SelectionEngine {

    // MARK: State resolution

    public static func singleState(day: Date, selection: Date?, calendar: Calendar) -> DaySelectionState {
        guard let selection else { return .none }
        return calendar.isDate(day, inSameDayAs: selection) ? .selected : .none
    }

    public static func multipleState(day: Date, selection: [Date], calendar: Calendar) -> DaySelectionState {
        selection.contains { calendar.isDate(day, inSameDayAs: $0) } ? .selected : .none
    }

    public static func rangeState(
        day: Date,
        range: ClosedRange<Date>?,
        anchor: Date?,
        calendar: Calendar
    ) -> DaySelectionState {
        // A pending anchor (first tap, awaiting the second) reads as selected.
        if range == nil {
            if let anchor, calendar.isDate(day, inSameDayAs: anchor) { return .selected }
            return .none
        }
        guard let range else { return .none }
        let lower = calendar.startOfDay(for: range.lowerBound)
        let upper = calendar.startOfDay(for: range.upperBound)
        let isLower = calendar.isDate(day, inSameDayAs: lower)
        let isUpper = calendar.isDate(day, inSameDayAs: upper)
        if isLower && isUpper { return .selected }
        if isLower { return .rangeStart }
        if isUpper { return .rangeEnd }
        if day > lower && day < upper { return .inRange }
        return .none
    }

    // MARK: Mutations

    /// Toggles a day in/out of a multiple selection, returning a sorted copy.
    public static func toggle(day: Date, in selection: [Date], calendar: Calendar) -> [Date] {
        let day = calendar.startOfDay(for: day)
        if let index = selection.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) }) {
            var copy = selection
            copy.remove(at: index)
            return copy
        }
        return (selection + [day]).sorted()
    }

    /// Result of tapping a day while in range mode.
    /// - With no anchor set, the tap becomes the new anchor (range cleared).
    /// - With an anchor set, the tap completes the range (anchor cleared).
    public static func rangeTap(
        day: Date,
        anchor: Date?,
        calendar: Calendar
    ) -> (anchor: Date?, range: ClosedRange<Date>?) {
        let day = calendar.startOfDay(for: day)
        if let anchor {
            let start = calendar.startOfDay(for: anchor)
            let lower = min(start, day)
            let upper = max(start, day)
            return (nil, lower...upper)
        }
        return (day, nil)
    }
}
