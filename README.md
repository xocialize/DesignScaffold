# DesignScaffold

The shared macOS design vocabulary for the fleet's demo and harness apps — extracted from
Apple's macOS 26/27 UI kit in Figma rather than estimated by eye — plus components dressed
in those tokens, shipped as separately selectable libraries.

## Products

| Library | What you get |
|---|---|
| `DesignScaffold` | `Tokens` + `cardSurface()` — the vocabulary |
| `DesignScaffoldCalendar` | Month calendar (single/multiple/range selection) in the house style; re-exports `DesignScaffold` |

In Xcode's package sheet, select only the libraries the app uses.

**The package is self-contained: zero external dependencies (SwiftUI only), by policy.**
Adopting any product never pulls in MLXEngine, a model package, or anything else.
Components are *vendored* — each one is its own target and selectable library, with its
look resolved through the tokens. The calendar was absorbed from SwiftCalendarKit (our
vanilla-calendar-pro port, now deprecated in favour of this copy); future components
follow the same pattern: new target, new selectable product, tokens win.

## Why it exists

Every demo app in the fleet was inventing its own spacing scale, radii, and type ramp. They
drifted from each other and from the platform. This package holds one copy, with the Figma
node ids recorded so it can be refreshed rather than re-guessed.

## Provenance

| | |
|---|---|
| File | `Demo Apps` — `LGwpgABHRfxj47V8uCmkwK` |
| Variables | node `9:937` (`Examples/Dialog/Save - Small`) |
| Grouped-form geometry | node `0:112` (`Form Group`) |
| Extracted | 2026-07-30 |

Raw variable dump, for diffing on refresh:

```
Body/Emphasized       SF Pro Semibold 13 / lh 16      Global/Radius      6
Headline/Regular      SF Pro Bold 13 / lh 16          Button/Radius      6
Subheadline/Regular   SF Pro Regular 11 / lh 14       Global/Height     24
Global/Font Size      13                              Cursor/Height     18
Labels/Primary        #ffffffd9                       Fields/Inset-L|R   8
Labels/Secondary      #ffffff8c                       Popup/Inset-Left  12
Window Background     #1e1e1e                         Button/Pad-Horiz  16
Accents/Blue          #0091ff                         Disclosure/Font   13
Accents/Red           #ff4245                         Form group radius 12, row 42, pad 10
Fills-Vibrant/Primary   #242424     Fills-Vibrant/Secondary  #141414
Labels-Vibrant/Primary  #f5f5f5     Labels-Vibrant/Secondary #8a8a8a
Liquid Glass: angle 0 · dispersion 20 · opacity 25 · frost 6 · refraction 70 · splay 20 · depth 30
```

## The colour policy (a judgement call, not a shortcut)

The kit publishes **dark values only**. Several are *exactly* the macOS system semantics:

| Figma | Value | System equivalent |
|---|---|---|
| `Labels/Primary` | `#ffffffd9` | `NSColor.labelColor` (white @ 85%) |
| `Labels/Secondary` | `#ffffff8c` | `NSColor.secondaryLabelColor` (white @ 55%) |
| `Window Background` | `#1e1e1e` | `NSColor.windowBackgroundColor` |

So where a semantic provably equals the token, **the semantic is used** — hardcoding the hex
would pin every app to dark mode and defeat Increase Contrast. The Figma value is recorded
beside it. Only genuinely brand-specific values (the accents) are carried as literals, and even
the blue defaults to the system accent so the user's own accent choice still applies.

Structural tokens — radii, control heights, insets, the type ramp — come straight from the kit.
That is where the estimates had actually been wrong: container radius was guessed at 10, the kit
says **12**.

## Refreshing from Figma

1. Select the relevant frame in Figma desktop (the remote MCP reads the live selection — with
   nothing selected it reports an empty document, which is misleading).
2. `get_variable_defs` on the node for the token values.
3. `get_design_context` on a representative component for geometry the variables don't carry
   (row heights, group padding).
4. Diff against the table above and update `Tokens.swift`.

## Usage

```swift
import DesignScaffold

Text("Real-time factor")
    .font(Tokens.Font.caption)
    .foregroundStyle(Tokens.Color.secondaryLabel)
    .padding(Tokens.Space.m)
    .cardSurface()
```

**House rule:** no view hardcodes a colour, font size, or spacing value. If something is
missing, add it here first — that constraint is what keeps a kit refresh a one-file change.

### Calendar

```swift
import DesignScaffoldCalendar   // re-exports DesignScaffold, so Tokens comes along

@State private var date: Date?                 // single
@State private var dates: [Date] = []          // multiple (tap to toggle)
@State private var range: ClosedRange<Date>?   // range (first tap = start, second = end)

CalendarView(range: $range)
    .firstWeekday(.monday)
    .bounds(minimum: .now)
    .disabledWeekdays(Weekday.weekend)
    .disabledDates { holidays.contains($0) }
    .showsWeekNumbers()
    .padding(Tokens.Space.s)
    .cardSurface()
```

The selection mode follows from which binding you pass (`Date?` / `[Date]` /
`ClosedRange<Date>?`). Behaviour — locale, calendar, bounds, disabled dates — is
configured via the chainable modifiers or a `CalendarConfiguration`; the grid math
(`MonthLayout`) and selection rules (`SelectionEngine`) are pure value types covered by
the package's unit tests.

**No theme call is needed: the scaffold look is the default.** Every colour, metric, and
font resolves through `Tokens` — a Figma token refresh re-skins the calendar for free.
Where the original port's choices disagreed with the tokens (8pt cell radius vs control
radius 6, 34pt cells vs control height 24, SwiftUI's `.headline`/`.callout` vs the
measured type ramp, opacity hacks vs real label semantics), **the token won** — each
divergence is recorded in `Sources/DesignScaffoldCalendar/Theme/CalendarTheme.swift`.
For brand accents, mutate a copy and pass it once:

```swift
var brand = CalendarTheme.scaffold
brand.accent = .pink
CalendarView(selection: $date).theme(brand)
```

There are no fixed light/dark palettes: the semantic tokens adapt, and forcing an
appearance is the host's job (`.preferredColorScheme(.dark)`).

## Adopters

- `mlxengine-audio/PROD/Audio8/Audio8 Demo`

## License

MIT — see [LICENSE](LICENSE).
