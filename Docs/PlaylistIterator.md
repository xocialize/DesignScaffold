# Playlist Iterator

`DesignScaffoldPlaylist` — a sortable playlist list: drag-to-reorder rows of
thumbnail · name · metadata, with tap selection and a distinct ACTIVE (current /
now-playing) marker.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="images/playlist-dark.png">
  <img src="images/playlist-light.png" width="822" alt="The playlist iterator: a populated list with an active ring and a selected row, a placeholder-thumbnail variant, and the empty state">
</picture>

*Row 1 wears the active ring, row 3 the selection wash — two different states. Right:
placeholder thumbnails and the empty state.*

Generalised from MarqueeStudio's playlist rail. The reorder runs on a `LazyVStack`
rather than `List.onMove` so tap-to-select is kept: the list reorders live as the
dragged row passes over neighbours and commits once on drop.

## Getting it

Select the `DesignScaffoldPlaylist` library when adding the package. The import
re-exports `DesignScaffold`, so `Tokens` and `cardSurface()` come along.

```swift
import DesignScaffoldPlaylist
```

## Usage

`Item` is your own row model — the view only needs `Identifiable` plus projections:

```swift
struct Clip: Identifiable {
    let id: Int64
    var title: String
    var start: String
    var runtime: String
    var artworkURL: URL?
}

@State private var clips: [Clip] = ...
@State private var selectedId: Int64?          // inspector subject
@State private var nowPlayingId: Int64?        // driven by the player

PlaylistIterator(
    items: $clips,                             // mutated live during a drag
    selection: $selectedId,                    // tap to select; tap again to clear
    active: nowPlayingId,                      // display-only accent ring
    name: { $0.title },
    metadata: { [PlaylistMetadatum("Start", $0.start), PlaylistMetadatum("TRT", $0.runtime)] }
) { clip in
    AsyncImage(url: clip.artworkURL) { $0.resizable().scaledToFill() } placeholder: { Color.clear }
}
.onReorder { reordered in persist(reordered.map(\.id)) }
```

### The reorder contract

`items` reorders **live** while a row is dragged (the list always reads as its final
order), and `onReorder` fires **once per completed drag** with the full re-ordered
array — persist the new order there. The live-move rule is a pure, unit-tested value
op (`PlaylistReorder.liveMove`), so the visual behaviour and the array mutation cannot
drift apart.

Verified end to end under a real pointer as well as in unit tests: dragging row 1 onto row 3
of a five-row list committed `2,3,1,4,5`, once. The `playlist` harness in
[the Component Lab](../DesignWorkspace/README.md) is the fixture.

### ⚠️ Reordering a FILTERED list

`onReorder` hands back the visible array. That is the whole list only if you pass the whole
list — and a playlist that gains filters is the normal direction of travel, not an edge case.
Under a filter the visible order says **nothing** about where the hidden rows sit, and applying
it to your backing array silently discards their positions.

Use `onPlace` there. It reports the move **relative** to its new neighbour:

```swift
.onPlace { placement in
    // "placement.moved now follows placement.after" — nil means it moved to the top
    // of what is SHOWN. Resolve against your full model.
    model.move(placement.moved, after: placement.after)
}
```

A relative placement survives any filter, because "X now follows Y" does not depend on what
sits between them being visible. Both callbacks fire, so an unfiltered list can keep using the
array.

### Selection vs. active

Two independent states, styled differently on purpose:

- **Selection** (`selection:` binding) — the wash. Tap to select, tap again to clear.
  This is the "inspector subject" in an editor. Omit the binding for a non-selectable list.
- **Active** (`active:` value) — the accent ring. The current / now-playing row.
  Display-only: advancing it is the player's job, not the list's.

### Thumbnails

Real thumbnails are app concerns (async loads, Metal textures), so they arrive as a
`ViewBuilder` and are clipped to the theme's square over the thumbnail well. Omit the
builder entirely to get the placeholder:

```swift
PlaylistIterator(items: $clips, name: { $0.title })   // placeholder thumbnails
```

### Chrome

| Modifier | Effect |
|---|---|
| `.showsIndex(false)` | Hide the 1-based position column |
| `.showsDragHandles(false)` | Hide the handles (rows stay draggable — the handle is an affordance, not the hit target) |
| `.emptyMessage("No clips yet.")` | The message centred over an empty list |
| `.onReorder { ... }` | The order-persist callback |
| `.theme(_:)` | Override the visual theme |

## Theming

Same pattern as the calendar: **the scaffold look is the default**, `PlaylistTheme`'s
initializer defaults are the token values, and a custom theme that only overrides
colours inherits the scaffold geometry.

```swift
var brand = PlaylistTheme.scaffold
brand.activeRing = .pink
brand.selectionWash = SwiftUI.Color.pink.opacity(0.15)
PlaylistIterator(items: $clips, name: { $0.title }).theme(brand)
```

The studio-to-token divergences (thumbnail 44 → row height 42, ad-hoc 10pt fonts → the
metric/mono tokens, selection wash opacity) are recorded in
[`Sources/DesignScaffoldPlaylist/Theme/PlaylistTheme.swift`](../Sources/DesignScaffoldPlaylist/Theme/PlaylistTheme.swift).

## Hosting

The list scrolls its own content and brings no background. Flush inside a card, clip to
the container radius so row washes don't poke past the corners:

```swift
PlaylistIterator(items: $clips, name: { $0.title })
    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container))
    .cardSurface()
```

> **Snapshotting note:** SwiftUI's `ImageRenderer` does not realize `LazyVStack`
> children, so headless captures of this component come out blank. Snapshot through an
> `NSHostingView` (a real AppKit hosting pass) instead.

## Row state, interaction hooks and the trailing column (0.21.0)

Asked for by MarqueeStudio (AB-A-0045) once its Editor rail sat in front of a real
sequencer — one that skips rows the resolver refuses — and the rail could not show which
rows those were. The split the operator ratified: **the package owns ordering and the house
style; the app owns row content and interaction.** Everything below is additive and
default-off: a 0.20.0 call site compiles unchanged and renders identically.

```swift
PlaylistIterator(items: $rows, selection: $selected, active: nowPlaying, name: \.title)
    .rowState { $0.hasFile ? .normal : .unavailable(reason: "No file for landscape") }
    .onActivate { take($0) }
    .rowContextMenu { row in
        Button("Take") { take(row) }
        Button("Reveal in Finder") { reveal(row) }
    }
    .rowActions { row in
        [ .toggle("Favourite", symbol: "star", isOn: row.favourite) { toggleFavourite(row) },
          .action("Export", symbol: "square.and.arrow.up")          { export(row) },
          .destructive("Delete", symbol: "trash")                   { delete(row) } ]
    }
```

### `rowState` — what the *player* will do, not what the list allows

Two visual states with app-defined meaning: `.unavailable(reason:)` dims name and metadata;
`.disabled(reason:)` dims and strikes the name. `reason` becomes the row's tooltip and is
spoken by VoiceOver — "unavailable, no file for landscape" — so a screen reader hears *why*
rather than that something is grey.

⚠️ **Rows stay selectable and draggable in every state.** The order is the operator's; the
state says what the sequencer will skip. A struck-through row that could not be dragged out
of the way would be actively in the way.

### `onActivate` — and the double-click that used to un-select

The row's single tap *toggles* selection. So before 0.21.0 a double-click selected the row
and then cleared it, which is the wrong thing to happen on the way to "Take". With
`onActivate` set, a double-click **selects the row and then activates it** — the Finder and
Mail convention — so a host binding it to Take or Open acts on the row the user just picked.
Unset, the row is byte-for-byte 0.20.0 — a plain `onTapGesture` with no double-tap wait
added to the single tap.

⚠️ The first cut claimed selection was "left as the first click set it". Driving the lab
showed `ACTIVATE` firing with no `SELECT` at all: `exclusively(before:)` swallows the first
click of a double-click entirely, so the row was activated without ever being selected.

### `rowActions` — declarative, and why

The trailing column could have been a bare `ViewBuilder`. There is one — `rowAccessory` —
for the genuinely custom case, but it is not the primary API, because **every real row-icon
set on the volume turned out to be the same three things.** ML[X] Audio Studio's take row is
a toggle (favourite), an action (export) and a destructive one (delete). MarqueeStudio asked
for icon buttons. The operator expects every Forge iterator to want them.

⚠️ **And Audio Studio had already paid for the column's absence, three times.** Its three
`PlaylistIterator` call sites all read `name: { ($0.favorite ? "★ " : "") + $0.title }` —
the toggle's *state* smuggled into the name string because the list had nowhere else to show
it. A screen reader announces that star as part of the title; the row cannot tint it; and it
is not actionable, so the row displays state it cannot change.

Given intent, the component owns what an app would otherwise re-decide: the button style,
the on/destructive tints (`actionOnTint` is amber because that is what Audio Studio's star
chose — promoted, not invented), the tooltip, the accessibility label and selected trait,
and the **44pt hit floor on iOS** via `Tokens.Layout.minimumHitTarget`, applied to the hit
area rather than the drawn glyph, exactly as `ChipRow` does.

`.toggle` follows the SF Symbols `.fill` convention when no `onSymbol` is given:
`star` → `star.fill`, `heart` → `heart.fill`.

### Three structural changes the column needed, all invisible to a 0.20.0 caller

The row used to be one hit target and one VoiceOver element. A button placed inside that
would have fought the drag, toggled selection on its way to being pressed, and been
**swallowed by `accessibilityElement(children: .combine)`** so a screen reader never found it.
Gestures, `onDrag` and the combined element now live on the *content* region; the trailing
column sits beside it with its own focusable buttons; the row groups them with `.contain`.
`onDrop` stays on the whole row — dropping onto any part of it is fine.

### Not added

An "up next" marker. One need (Marquee), and the app can draw it in the thumbnail well it
already owns. It gets promoted when a second app asks — the same rule that kept the leading
icon out of `SectionHeader`.

