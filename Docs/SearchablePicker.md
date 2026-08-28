# Searchable Picker

A findable selection list for large libraries — search, tag scoping, sort, and optional
multi-select over thousands of rows.

```swift
import DesignScaffoldPicker

SearchablePicker(items) { id in open(id) }
```

Multi-select, with a footer that commits the batch:

```swift
SearchablePicker(items, addVerb: "Add") { ids in append(ids) }
```

The host loads the items and owns what a selection **does**; the picker owns **finding**.
Rendering is lazy, so length is not the bottleneck.

## Promoted, not designed

From MarqueeStudio, where it already served three call sites. Two things changed on the way in,
because *reusable* and *generic* are not the same claim.

⚠️ **Recency is host-supplied.** It sorted "Recent" by `id > id`, which quietly assumed an
AUTOINCREMENT primary key — true in that app, meaningless for a `UUID`, where it would have
produced a confident but arbitrary order. `PickerItem.recencyRank` is now explicit, and **the
Recent option is not offered at all when no item carries one**: a component should not present
a sort it cannot perform.

⚠️ **The tag chips are `ChipRow`.** It had grown its own horizontally *scrolling* chip strip —
the exact shape `ChipRow`'s documentation argues against, since a filter row that scrolls hides
its own options. `ChipRow` gained a multi-select mode rather than a second chip implementation
being allowed to stand.

## The find pipeline

`PickerFilter` is pure and unit-tested — it decides what a user can find, which no screenshot
can show. Two behaviours are deliberate and both are asserted:

- **Scope, then search, then sort.** Scoping first means the count reflects the chips the user
  can see, so a fruitless search inside an active scope reads as "not in this tag" rather than
  "not in the library".
- **Several chips are a UNION, not an intersection.** Chips *widen* a search. Requiring every
  active tag would make a second chip almost always empty the list, which reads as broken.
- An item with no `recencyRank` sorts **last** under Recent. Absence of a recency is not
  evidence of being new.

## The disabled footer

⚠️ Its label is `.white` **only** on the solid accent fill. On the disabled fill it takes the
normal label colour and lets `.disabled()` do the dimming — asking for a muted colour as well
dims twice and lands well under the contrast macOS's own disabled buttons carry. Both halves of
that were live defects, invisible until the app was first run in light appearance.

## Theming

`SearchablePickerTheme` follows the house pattern — initializer defaults are the token values,
`.theme(_:)` overrides.
