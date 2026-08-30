# Metric Tile

One headline measurement, presented so the **number** is what the eye lands on.

```swift
import DesignScaffoldMetrics

MetricGrid {
    MetricTile("0.31", label: "Time to first audio", unit: "s").carded()
    MetricTile("2.41", label: "Resident", unit: "GB", caption: "1 of 1 resident").carded()
    MetricTile("−0.2", label: "Peak", unit: "dBFS",
               caption: "clipped", emphasis: Tokens.Color.failure).carded()
}
```

## Promoted into tokens that were already waiting

Nemotron ASR, Audio8, MageVL and LLM Voice Chat each built this. The unusual part is that **the
vocabulary already existed**: `Tokens.Font.metricValue`, `.metricLabel`, `.metricInline`, and
`Tokens.Layout.metricTileMinWidth` — whose own comment records a metric grid that silently fell
back to a wider layout at 132pt.

The tokens were added for a component nobody built, so four apps built their own against them.

The shape here is Audio8's, which was the most developed of the four and already token-based.

## ⚠️ Shrink, never truncate

A clipped number is a **wrong** number. `2.4…` reads as a value and the reader has no way to
know it is not one. The value line is `lineLimit(1)` with `minimumScaleFactor`, so a long figure
gets smaller rather than losing digits — verified with `1,284,905,772` in a 140pt tile.

## `emphasis` is the host's, everything else is the vocabulary's

A metric's value sometimes carries a **verdict** — a clipped peak, a silent render, a budget
exceeded. Only the host knows what good looks like, so that colour is a parameter. Every other
colour and font comes from tokens.

## The grid

`MetricGrid` wraps at `Tokens.Layout.metricTileMinWidth` (140). That number is load-bearing: at
132, two tiles did **not** fit inside `inspectorWidth` minus padding and the grid silently fell
back to one column — which reads as a layout bug rather than as a measurement.

Verified in the Component Lab: two columns at an inspector's 340pt, four at 700pt.

## Themes

- `.scaffold` — the carded tile, the default. Add the card with `.carded()`.
- `.inline` — no card, tighter type, label not uppercased. For a metric inside chrome that
  already has a surface, such as a sidebar's resident-memory block.

## Accessibility

The tile reads as a sentence with the **label first**: "time to first audio, 0.31 s" is a fact;
"0.31, time to first audio" is a quiz.
