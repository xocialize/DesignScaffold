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
