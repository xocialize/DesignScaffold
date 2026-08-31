//
//  ⚠️ macOS-only, and only because `@Previewable` is iOS 17+. This is DEVELOPMENT code —
//  guarding it keeps the package's iOS floor at 16, where the SHIPPING code actually sits,
//  instead of letting a preview macro set the floor for every consumer. See Docs/PLATFORMS.md.
//
#if os(macOS)

//  CalendarScaffold+Previews.swift
//  Canvas gallery for the calendar on the scaffold's card surface, which is how fleet
//  apps actually host it. No theme calls: the scaffold look IS the default.

import DesignScaffold
import SwiftUI

#Preview("Single date, on card") {
    @Previewable @State var date: Date? = .now
    CalendarView(selection: $date)
        .padding(Tokens.Space.s)
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 340)
}

#Preview("Range + week numbers, on card") {
    @Previewable @State var range: ClosedRange<Date>?
    CalendarView(range: $range)
        .firstWeekday(.monday)
        .showsWeekNumbers()
        .padding(Tokens.Space.s)
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 380)
}

#Preview("Bounded, weekends disabled, dark") {
    @Previewable @State var date: Date? = .now
    CalendarView(selection: $date)
        .bounds(minimum: .now)
        .disabledWeekdays(Weekday.weekend)
        .padding(Tokens.Space.s)
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 340)
        .preferredColorScheme(.dark)
}

#Preview("Custom theme override") {
    @Previewable @State var dates: [Date] = []
    var brand = CalendarTheme.scaffold
    brand.accent = .pink
    brand.todayIndicator = .pink
    brand.inRangeBackground = SwiftUI.Color.pink.opacity(0.15)
    return CalendarView(selection: $dates)
        .theme(brand)
        .padding(Tokens.Space.s)
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 340)
}

#endif
