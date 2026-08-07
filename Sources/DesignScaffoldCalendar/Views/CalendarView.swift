import SwiftUI

/// A themeable SwiftUI month calendar supporting single, multiple, and range
/// selection.
///
/// ```swift
/// // Single date — scaffold-themed by default
/// CalendarView(selection: $date)
///
/// // Multiple dates, week starting Monday, custom accent
/// var brand = CalendarTheme.scaffold
/// brand.accent = .pink
/// CalendarView(selection: $dates)
///     .firstWeekday(.monday)
///     .theme(brand)
///
/// // Date range with bounds and disabled weekends
/// CalendarView(range: $range)
///     .bounds(minimum: .now)
///     .disabledWeekdays(Weekday.weekend)
///     .showsWeekNumbers(true)
/// ```
///
/// Behaviour is configured via ``CalendarConfiguration`` (or the chainable
/// modifiers in `CalendarView+Modifiers`), and styling via ``CalendarTheme``.
public struct CalendarView: View {

    /// Which binding the calendar drives, and therefore its selection mode.
    enum SelectionBinding {
        case single(Binding<Date?>)
        case multiple(Binding<[Date]>)
        case range(Binding<ClosedRange<Date>?>)
    }

    @State private var visibleMonth: Date
    /// First tap of a range, awaiting the second tap.
    @State private var rangeAnchor: Date?

    var configuration: CalendarConfiguration
    var themeOverride: CalendarTheme?
    let selection: SelectionBinding

    /// Resolved theme — the override if set, otherwise the scaffold house style.
    var theme: CalendarTheme { themeOverride ?? .scaffold }

    // MARK: Initialisers

    /// Single-date selection.
    public init(selection: Binding<Date?>, configuration: CalendarConfiguration = .init()) {
        self.selection = .single(selection)
        self.configuration = configuration
        self.themeOverride = nil
        let initial = selection.wrappedValue ?? Date()
        _visibleMonth = State(initialValue: configuration.resolvedCalendar.startOfDay(for: initial))
    }

    /// Multiple-date selection.
    public init(selection: Binding<[Date]>, configuration: CalendarConfiguration = .init()) {
        self.selection = .multiple(selection)
        self.configuration = configuration
        self.themeOverride = nil
        let initial = selection.wrappedValue.first ?? Date()
        _visibleMonth = State(initialValue: configuration.resolvedCalendar.startOfDay(for: initial))
    }

    /// Date-range selection.
    public init(range: Binding<ClosedRange<Date>?>, configuration: CalendarConfiguration = .init()) {
        self.selection = .range(range)
        self.configuration = configuration
        self.themeOverride = nil
        let initial = range.wrappedValue?.lowerBound ?? Date()
        _visibleMonth = State(initialValue: configuration.resolvedCalendar.startOfDay(for: initial))
    }

    // MARK: Body

    public var body: some View {
        let layout = MonthLayout(containing: visibleMonth, configuration: configuration)
        MonthView(
            layout: layout,
            configuration: configuration,
            theme: theme,
            title: configuration.monthTitle(for: visibleMonth),
            stateProvider: state(for:),
            onSelect: select(_:),
            onPreviousMonth: { changeMonth(by: -1) },
            onNextMonth: { changeMonth(by: 1) },
            onToday: goToToday
        )
        .animation(.easeInOut(duration: 0.18), value: visibleMonth)
    }

    // MARK: Selection state

    private func state(for day: CalendarDay) -> DaySelectionState {
        let calendar = configuration.resolvedCalendar
        switch selection {
        case .single(let binding):
            return SelectionEngine.singleState(day: day.date, selection: binding.wrappedValue, calendar: calendar)
        case .multiple(let binding):
            return SelectionEngine.multipleState(day: day.date, selection: binding.wrappedValue, calendar: calendar)
        case .range(let binding):
            return SelectionEngine.rangeState(day: day.date, range: binding.wrappedValue, anchor: rangeAnchor, calendar: calendar)
        }
    }

    private func select(_ day: CalendarDay) {
        guard !configuration.isDisabled(day.date) else { return }
        let calendar = configuration.resolvedCalendar
        switch selection {
        case .single(let binding):
            binding.wrappedValue = day.date
        case .multiple(let binding):
            binding.wrappedValue = SelectionEngine.toggle(day: day.date, in: binding.wrappedValue, calendar: calendar)
        case .range(let binding):
            let result = SelectionEngine.rangeTap(day: day.date, anchor: rangeAnchor, calendar: calendar)
            rangeAnchor = result.anchor
            binding.wrappedValue = result.range
        }
    }

    // MARK: Navigation

    private func changeMonth(by delta: Int) {
        let calendar = configuration.resolvedCalendar
        if let next = calendar.date(byAdding: .month, value: delta, to: visibleMonth) {
            visibleMonth = calendar.startOfDay(for: next)
        }
    }

    private func goToToday() {
        let calendar = configuration.resolvedCalendar
        let comps = calendar.dateComponents([.year, .month], from: Date())
        if let monthStart = calendar.date(from: comps) {
            visibleMonth = monthStart
        }
    }
}
