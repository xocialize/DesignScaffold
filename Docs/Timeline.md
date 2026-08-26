# Timeline

`DesignScaffoldTimeline` — a media-agnostic multi-track timeline: ruler, track headers,
clip lanes, playhead. Generic over a clip model the consumer supplies.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="images/timeline-dark.png">
  <img src="images/timeline-light.png" width="880" alt="The timeline at two zoom levels: ruler with adaptive ticks, V1/A1/Subs track headers with state controls, clip lanes with a selected clip, and the playhead">
</picture>

*Two zoom levels of the same edit. The tick interval steps 1s → 5s on its own; everything
else is identical because it all derives from one geometry.*

> **Status: T1.** Ruler (adaptive ticks, timecode, click/drag scrub) · track headers (name,
> state controls, app accessory slot) · clip lanes (layout, selection rendering, tap-select)
> · playhead · zoom. **T2** adds drag, cross-track move, edge trim and snapping; **T3** adds
> in/out brackets, gap indicators, marquee select and row-height resize.

## Scope — what this owns, and what it deliberately does not

| The scaffold owns | The consumer owns |
|---|---|
| Ruler, ticks, timecode, scrub | What a clip *means* — filmstrips, waveforms, take chips |
| Track headers and state controls | Generation overlays, resolution stripes, transition ramps |
| Lane layout, clip placement/sizing | The clip body view, entirely |
| Playhead, zoom, selection, (T2) drag/trim/snap | Monitors, inspectors, the tool rail |

The tool rail on the spec artboard is **app chrome** — place the timeline beside your own
rail. It is drawn there for context, not as a component boundary.

## Usage

```swift
import DesignScaffoldTimeline

struct Clip: TimelineClip {          // the whole contract
    let id: UUID
    var start: TimeInterval
    var duration: TimeInterval
    var trackIndex: Int
    var asset: Asset                 // …and whatever else you need
}

@State private var geometry = TimelineGeometry(pointsPerSecond: 60)
@State private var playhead: TimeInterval = 0
@State private var selection: Set<Clip.ID> = []

TimelineView(tracks: tracks, clips: clips,
             geometry: $geometry, playhead: $playhead, selection: $selection) { clip in
    Filmstrip(clip.asset)            // you draw the inside
}
.frameRate(24)
.onToggleControl { track, control in model.toggle(control, on: track) }
```

Tracks declare which state controls their header offers, so an audio row can show
mute/solo while a subtitle row shows only enable:

```swift
TimelineTrack(id: "a1", name: "A1", kind: .audio, controls: [.mute, .solo, .lock])
```

`Kind` sets the default row height (video 64, audio 44, subtitle 28); set `height`
explicitly to override. A `headerAccessory` ViewBuilder carries anything app-specific —
the spec's source-patch picker, for instance.

## One geometry, therefore no scroll sync

Ruler, headers and lanes all read a single ``TimelineGeometry`` (`pointsPerSecond` +
`visibleStart`). Panning and zooming are writes to that one value, so the three surfaces
cannot drift apart — **there are no scroll offsets to reconcile.** A nested-ScrollView
design has to solve that problem continuously; this one cannot have it. It also gives
virtualisation for free: lanes build only the clips intersecting the viewport.

```swift
geometry.zoom(to: 120, keeping: playhead)   // anchored zoom — the anchor stays put
geometry.scroll(to: 30)                     // never negative
```

## The snapping rule

**The snap threshold is expressed in POINTS and converted to time at the current zoom:**

```swift
let tolerance = geometry.seconds(forPoints: theme.snapThreshold)   // 8pt, always
```

A hardcoded seconds threshold drifts badly at the extremes — 0.2s is 2pt at 10pt/s
(imperceptible) and 80pt at 400pt/s (grabs everything). Points-in, seconds-out keeps the
*feel* identical at every zoom, and it is unit-tested across three orders of magnitude.
(T2 wires the pluggable snap sources on top of this; the conversion already exists so
consumers can build against it now.)

## Theming — and two documented departures from the spec

`TimelineTheme`'s initializer defaults are the token values. Two spec values were changed
on the way in rather than applied silently:

| Spec says | Ships as | Why |
|---|---|---|
| selection `accentFigma` (#0091ff literal) | `Tokens.Color.accent` | The system accent keeps the timeline consistent with every other component and honours the user's accent + Increase Contrast. An editor wanting fixed brand blue sets `theme.selection = Tokens.Color.accentFigma` — a deliberate app override, not the library default. |
| playhead "`failure` #ff4245" | its own literal (same value) | A playhead is not an error. Binding it to the failure semantic means a future change to error red silently moves the playhead. Same colour today, independent meaning. |

## Under the hood

`TimelineGeometry`, `TickScale` and `Timecode` are pure value types with 22 unit tests —
the time⇄points mapping, zoom clamping and anchoring, viewport virtualisation, the
points-based snap conversion, tick-ladder selection, and timecode formatting.

One behaviour worth knowing: the ruler always includes the aligned tick **at or before**
the left edge, because a tick's label is drawn to its right and can still be on screen.
An earlier version admitted it only within half an interval, which made the leading label
blink in and out as the scroll moved within a single interval.
