# Loading Modal

`DesignScaffoldLoading` — a modal loading card for model/product loads: a display-size
percentage with a smaller % suffix, an uppercase status line, dot-separated detail
fields, and a thin progress bar, anchored bottom-left over an optional full-bleed
background.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="images/loading-dark.png">
  <img src="images/loading-light.png" width="825" alt="The loading modal over a dimmed app: hero percentage, status line, detail fields, and progress bar, bottom-left on an 800×600 card">
</picture>

*Light: the plain card before art exists. Dark mode shows the background-art slot
filled, with the legibility scrim.*

The LAYOUT follows the Bonsai 27B WebGPU space's loading readout; the type and colour
are the scaffold's own — semantic label ramp, the kit's caption/mono fonts, an accent
bar. The card is 800×600 with a slot for product/model art behind the readout.

## Getting it

Select the `DesignScaffoldLoading` library when adding the package. The import
re-exports `DesignScaffold`, so `Tokens` and `cardSurface()` come along.

```swift
import DesignScaffoldLoading
```

## Usage

You pass in the percentage and the fields — the component renders, nothing more:

```swift
@State private var loading = false
@State private var progress = LoadingProgress(fraction: 0, status: "Preparing")

MyAppContent()
    .loadingModal(isPresented: loading, progress: progress, title: "Audio8 TTS")
```

Feed it from your loader's callbacks (for MLXEngine, map the download / materialise /
compile / warmup phases into updates):

```swift
progress = LoadingProgress(
    fraction: 0.29,
    status: "Streaming weights",
    fields: ["1.13 / 3.79 GB", "Tensor 193/851", "25 MB/s", "ETA 1:17"])
```

- `fraction` — 0…1, clamped on display. The percentage **floors** (99.9% reads "99"),
  so "100" appears only when the load is actually complete.
- `status` — the phase line, rendered uppercase in the fleet's micro-header treatment.
- `fields` — free-form segments joined with " · "; empty ones are dropped. Formatting
  (byte counts, ETAs) is the app's business — the card just displays.

There is deliberately no close affordance: dismissal is the load's job, not the
user's. Drive `isPresented` from the load lifecycle.

### Background art

The card takes a `ViewBuilder` background — product or model art, clipped to the card,
with a legibility scrim faded in behind the readout. Until art exists, omit it for the
plain scaffold surface:

```swift
.loadingModal(isPresented: loading, progress: progress, title: "Bernini R") {
    Image("bernini-key-art").resizable().scaledToFill()
}
.preferredColorScheme(.dark)   // dark imagery wants light text — force the scheme
```

`LoadingCard` is also public for direct embedding (a launch screen, a settings pane)
without the modal chrome.

## Theming

Same pattern as the other components: **the scaffold look is the default**,
`LoadingTheme`'s initializer defaults are the token values, and a custom theme that
only overrides colours inherits the scaffold geometry (card size included — override
`cardWidth`/`cardHeight` there if 800×600 doesn't fit the host).

The reference site's prism bar gradient is kept available for surfaces that want it:

```swift
var t = LoadingTheme.scaffold
t.barColors = LoadingTheme.prismBarColors   // white → red → gold → green → blue → violet
LoadingCard(progress: progress).theme(t)
```

## Under the hood

`LoadingProgress`'s display projections (percent flooring with the binary-representation
epsilon — 0.29 must read "29", not "28" — clamping, field joining) are pure and
unit-tested.
