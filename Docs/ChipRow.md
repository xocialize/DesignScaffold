# Chip Row

`DesignScaffoldChips` — capsule filter chips, single-select, wrapping when the row runs out
of width.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="images/chips-dark.png">
  <img src="images/chips-light.png" width="600" alt="Four filter chips on one row with Video active, and the same component wrapping a longer set across three rows in a narrow sidebar">
</picture>

*Left: an assets panel, four chips on one row. Right: the same component in a narrow
sidebar, wrapping.*

## Usage

```swift
import DesignScaffoldChips

enum Kind: String, CaseIterable, Identifiable {
    case all, video, image, audio
    var id: Self { self }
}
@State private var kind: Kind.ID = .all

ChipRow(Kind.allCases, selection: $kind) { $0.rawValue.capitalized }
```

Generic over any `Identifiable` collection with a string label — the component knows nothing
about what is being filtered.

## Single-select, deliberately

The selection is a plain `Binding<Item.ID>`: exactly one chip is always active. Both observed
uses have an "All" chip and neither has ever wanted multi-select, so there is no
multi-select mode and no `allowsMultiple` flag.

A multi-select filter is a **different component with a different affordance** (checkable
chips read differently from a segmented choice), not a boolean on this one. Adding it
speculatively would mean inventing an interaction nobody has asked for and then maintaining
it.

## Wrapping is a `Layout`, not a `ScrollView`

Chips wrap to a new row rather than scrolling. A filter row that scrolls hides its own
options; one that clips loses them silently. A chip wider than the entire row still gets its
own row rather than being dropped — clipping one long label is bad, losing it is worse.

The packing arithmetic (`ChipFlow`) is a pure function with unit tests, including the classic
off-by-one: **spacing counts toward the width when deciding to wrap.**

## Theming

`ChipRowTheme` follows the house pattern — initializer defaults are the token values, and
`.theme(_:)` overrides.

One divergence from the source artboard, recorded rather than applied silently: it specifies
**3pt vertical / 9pt horizontal** padding, both a point off the 4pt grid, which reads as
drawn by eye for this element. The defaults use `Space.xs` (4) and `Space.s` (8). A caller
who wants the artboard's exact figures sets them on the theme.
