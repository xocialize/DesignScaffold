import SwiftUI

/// A single tappable day button. Stateless: every visual decision is derived from
/// the inputs so it stays cheap to re-render.
struct DayCell: View {
    let day: CalendarDay
    let label: String
    let accessibilityLabel: String
    let state: DaySelectionState
    let isToday: Bool
    let isDisabled: Bool
    let isWeekend: Bool
    let theme: CalendarTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(theme.dayFont)
                .monospacedDigit()
                .frame(minWidth: theme.cellMinSize, minHeight: theme.cellMinSize)
                .frame(maxWidth: .infinity)
                .foregroundStyle(textColor)
                .background(cellBackground)
                .overlay(todayOverlay)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(day.isWithinDisplayedMonth || state != .none ? 1 : 0.9)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(state != .none ? .isSelected : [])
        .accessibilityRemoveTraits(isDisabled ? .isButton : [])
    }

    private var textColor: Color {
        if isDisabled { return theme.disabledText }
        switch state {
        case .selected, .rangeStart, .rangeEnd:
            return theme.selectedDayText
        case .inRange:
            return theme.dayText
        case .none:
            if !day.isWithinDisplayedMonth { return theme.outsideMonthText }
            if isWeekend { return theme.weekendText }
            return theme.dayText
        }
    }

    @ViewBuilder
    private var cellBackground: some View {
        switch state {
        case .selected, .rangeStart, .rangeEnd:
            RoundedRectangle(cornerRadius: theme.cellCornerRadius, style: .continuous)
                .fill(theme.accent)
        case .inRange:
            Rectangle().fill(theme.inRangeBackground)
        case .none:
            Color.clear
        }
    }

    @ViewBuilder
    private var todayOverlay: some View {
        if isToday && state == .none {
            RoundedRectangle(cornerRadius: theme.cellCornerRadius, style: .continuous)
                .strokeBorder(theme.todayIndicator, lineWidth: 1.5)
        }
    }
}
