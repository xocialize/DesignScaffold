import SwiftUI

/// Renders one month: header (title + navigation), weekday symbols, and the 6×7
/// grid of ``DayCell``s, with an optional leading week-number column.
struct MonthView: View {
    let layout: MonthLayout
    let configuration: CalendarConfiguration
    let theme: CalendarTheme
    let title: String
    let stateProvider: (CalendarDay) -> DaySelectionState
    let onSelect: (CalendarDay) -> Void
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onToday: () -> Void

    private var calendar: Calendar { configuration.resolvedCalendar }

    var body: some View {
        VStack(spacing: 12) {
            header
            grid
        }
        .padding(12)
        .background(theme.background)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(theme.titleFont)
                .foregroundStyle(theme.headerText)
            Spacer(minLength: 8)
            if configuration.showsTodayButton {
                Button(action: onToday) {
                    Text(todayButtonTitle).font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accent)
                .accessibilityLabel(Text("Go to today"))
            }
            navButton(systemName: "chevron.left", action: onPreviousMonth, label: "Previous month")
            navButton(systemName: "chevron.right", action: onNextMonth, label: "Next month")
        }
    }

    private func navButton(systemName: String, action: @escaping () -> Void, label: String) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.accent)
        .accessibilityLabel(Text(label))
    }

    private var grid: some View {
        Grid(horizontalSpacing: theme.cellSpacing, verticalSpacing: theme.cellSpacing) {
            GridRow {
                if configuration.showsWeekNumbers {
                    weekNumberHeaderCell
                }
                ForEach(layout.orderedWeekdays, id: \.self) { weekday in
                    Text(configuration.shortSymbol(for: weekday))
                        .font(theme.weekdaySymbolFont)
                        .foregroundStyle(theme.weekdaySymbolText)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }
            ForEach(Array(layout.weeks.enumerated()), id: \.offset) { index, week in
                GridRow {
                    if configuration.showsWeekNumbers {
                        Text("\(layout.weekNumbers[index])")
                            .font(theme.weekdaySymbolFont)
                            .foregroundStyle(theme.weekNumberText)
                            .frame(minWidth: 20)
                            .accessibilityLabel(Text("Week \(layout.weekNumbers[index])"))
                    }
                    ForEach(week) { day in
                        DayCell(
                            day: day,
                            label: configuration.dayNumber(for: day.date),
                            accessibilityLabel: configuration.accessibilityLabel(for: day.date),
                            state: stateProvider(day),
                            isToday: calendar.isDateInToday(day.date),
                            isDisabled: configuration.isDisabled(day.date),
                            isWeekend: configuration.isWeekend(day.date),
                            theme: theme,
                            action: { onSelect(day) }
                        )
                    }
                }
            }
        }
    }

    private var weekNumberHeaderCell: some View {
        Text(weekNumberHeaderSymbol)
            .font(theme.weekdaySymbolFont)
            .foregroundStyle(theme.weekNumberText)
            .frame(minWidth: 20)
            .accessibilityHidden(true)
    }

    private var weekNumberHeaderSymbol: String { "wk" }
    private var todayButtonTitle: String { "Today" }
}
