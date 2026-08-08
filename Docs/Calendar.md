# Calendar

`DesignScaffoldCalendar` — a month calendar for date, multi-date, and date-range input,
in the scaffold house style.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="images/calendar-dark.png">
  <img src="images/calendar-light.png" width="732" alt="The calendar in the default scaffold theme next to a custom accent override">
</picture>

*Left: the default — no theme call. Right: the same calendar with a custom accent.*

Ported from [vanilla-calendar-pro](https://github.com/uvarov-frontend/vanilla-calendar-pro)'s
look and selection ergonomics (via the now-deprecated SwiftCalendarKit, folded into this
package), then re-based on the scaffold tokens.

## Getting it

Select the `DesignScaffoldCalendar` library when adding the package. The import
re-exports `DesignScaffold`, so `Tokens` and `cardSurface()` come along.

```swift
import DesignScaffoldCalendar
```

## Selection modes

The mode follows from which binding you pass:

```swift
@State private var date: Date?                 // single — tap a day
CalendarView(selection: $date)

@State private var dates: [Date] = []          // multiple — tap to toggle days in/out
CalendarView(selection: $dates)

@State private var range: ClosedRange<Date>?   // range — first tap = start, second = end
CalendarView(range: $range)
```

## Configuring

Every behaviour is a chainable modifier (each returns a configured copy), or build a
`CalendarConfiguration` up front and pass it to the initializer.

| Modifier | Effect |
|---|---|
| `.firstWeekday(.monday)` | The day the week grid starts on |
| `.locale(Locale(identifier: "en_GB"))` | Month titles + weekday symbols |
| `.calendar(_:)` | The `Calendar` used for all date math (time zone honoured) |
| `.bounds(minimum:maximum:)` | Clamp the selectable range (either side optional) |
| `.disabledWeekdays(Weekday.weekend)` | Weekdays that cannot be selected |
| `.weekendDays(_:)` | Weekdays drawn in the weekend colour (styling only) |
| `.disabledDates { holidays.contains($0) }` | Disable arbitrary days by predicate |
| `.showsWeekNumbers()` | Leading ISO week-of-year column |
| `.showsTodayButton(false)` | Hide the "Today" shortcut in the header |

Every day is a focusable button with a full-date accessibility label.

## Theming

**No theme call is needed — the scaffold look is the default.** Every colour, metric,
and font resolves through `Tokens`, so a Figma token refresh re-skins the calendar with
no code change. For brand accents, mutate a copy and pass it once:

```swift
var brand = CalendarTheme.scaffold
brand.accent = .pink
brand.todayIndicator = .pink
CalendarView(selection: $date).theme(brand)
```

`CalendarTheme`'s initializer defaults *are* the token values, so a custom theme that
only overrides colours still inherits the scaffold geometry. There are no fixed
light/dark palettes: the semantic tokens adapt, and forcing an appearance is the host's
job (`.preferredColorScheme(.dark)`).

Where the original port's choices disagreed with the tokens, the token won — each
divergence (cell radius 8 → 6, cell size 34 → 24, the type ramp, the label semantics)
is recorded in
[`Sources/DesignScaffoldCalendar/Theme/CalendarTheme.swift`](../Sources/DesignScaffoldCalendar/Theme/CalendarTheme.swift).

## Hosting

The calendar brings no background of its own — pair it with the scaffold card:

```swift
CalendarView(selection: $date)
    .padding(Tokens.Space.s)
    .cardSurface()
```

## Under the hood

The grid geometry (`MonthLayout`) and selection rules (`SelectionEngine`) are pure value
types with no SwiftUI dependency, covered by the package's unit tests; the views are thin
renderers over that core.
