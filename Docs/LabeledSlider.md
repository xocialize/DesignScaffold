# Labeled Slider

A parameter row: the label on the left, its current value on the right, the track beneath.

```swift
import DesignScaffoldControls

LabeledSlider("Temperature", value: $temperature, in: 0...2)                  // 2 decimals
LabeledSlider("Guidance (CFG)", value: $guidance, in: 1...10, decimals: 1)
LabeledSlider("Max tokens", value: $maxTokens, in: 32...2048)                 // Int binding
LabeledSlider("Max frames", value: $maxFrames, in: 64...2048, step: 32, unit: " frames")
LabeledSlider("Speed", value: $speed, in: 0.5...2) { "\($0.formatted(.number))×" }
LabeledSlider("Image guidance", value: $g, in: 0...10, decimals: 1,
              caption: "how closely the edit follows the input image")
```

## Promoted from seven copies

| where | spelling |
|---|---|
| Audio8 Demo `UI/Components.swift` | `struct ParameterSlider: View` |
| SenseNova-U1.5 Demo `UI/CreateView.swift` | `struct SliderRow: View` |
| Liquid LFM 2.5 Demo `UI/SidebarView.swift` | `func slider(…)` **and** `func intSlider(…)` |
| ML[X] LTX Studio `UI/ClipInspector.swift` | `func slider(…)` |
| Mage Demo `ContentView.swift` | `func sliderRow(…)` |
| Moebius Demo `UI/RootView.swift` | `func slider(…)` |
| Gepard Demo `UI/GepardDemoView.swift` | `func knobSlider(…)` |

Liquid LFM had grown a *second* one to handle integers, which is the clearest signal in the
set that the abstraction was missing rather than merely duplicated.

## What this fixes, rather than merely centralises

**Integer parameters stop being the call site's problem.** Four of the nine call sites
migrated in the same pass hand-wrote a `Binding<Double>` wrapper around an `Int`, and the two
apps disagreed about how: SenseNova wrote `Int($0.rounded())`, Audio8 wrote `Int($0)`.
Truncation loses a whole unit at the top of a drag — `Int(511.9999)` is `511` — and it hides
whenever the step grid lands on exact integers, which is most of the time and none of the
times that matter. `SliderReadout.integer(_:in:)` rounds and clamps, once.

**The readout is not a C format string.** All seven passed `"%.2f"`/`"%.1f"`/`"%.0f"` down from
the call site. `String(format:)` is unchecked, and it does not localise — a German user reads
`0.85` in a panel where every other number says `0,85`. `decimals:` is what the caller means
and the compiler can see it.

**VoiceOver gets a slider that says what it is.** Every copy built a bare `Slider(value:in:)`
with a `Text` beside it, so a screen reader announced an unnamed "slider" and, separately, a
floating number. Here the title is the slider's `accessibilityLabel`, the readout is its
`accessibilityValue`, and the visible readout is hidden from the tree rather than read twice.

## ⚠️ The readout echoes the binding — it does not predict the step grid

The first version snapped the readout to the step grid, on the reasoning that the number
should agree with the track. Driving the Component Lab showed it produced exactly the
disagreement it was meant to prevent: a row initialised to 50 on a 0…100-by-30 slider rendered
its **knob at 50** and its **readout at 60**, because `Slider(value:in:step:)` snaps values it
is dragged to, never one it was handed.

The binding is the truth. SwiftUI owns the stepping and writes stepped values back on
interaction, so echoing the binding is what keeps the two in step. Clamping stays, because a
value outside the range pins the knob and printing the out-of-range number would describe
something the control cannot show.

Measured while confirming this: **when the step does not divide the range, the top is
unreachable.** 0…100 by 30 stops at 90. That is SwiftUI's behaviour, and the readout now
follows it instead of guessing at it.

## What the host still owns

`.help(_:)`, `.tint(_:)` and `.controlSize(_:)` are ordinary modifiers — apply them to the row,
or to a whole inspector at once. There is deliberately **no** `help:` parameter: Audio8's copy
had one and wrote `.help(help ?? "")`, attaching an empty tooltip to every row that did not
want one.

## Themes

`.scaffold` (default) leads with the title: `caption`/`label` for the title,
`metricInline`/`secondaryLabel` for the readout. `.valueForward` inverts the two, which is what
Audio8's copy did deliberately — in a panel of sampling parameters the titles are read once and
the numbers are what you are moving.

The defaults were settled by counting only the copies already speaking in `Tokens`. A naive
majority across all seven would have got the title font wrong: `body` wins 4–3 overall, but
three of those four style themselves from `MarqueeFont`/`MarqueeColor` or bare `.system(size:)`
— the parallel vocabulary AB-D-0042 exists to retire, and therefore not votes about this one.
Among the four token-native copies, `caption` wins 3–1.

The readout is `metricInline` (12pt, `.monospacedDigit()`) rather than a fully monospaced face:
six of seven used *some* monospacing, but the requirement underneath is narrower — live digits
must not jitter as they tick — and monospaced digits alone achieve it while leaving a unit
suffix like `×` or `fps` reading as text rather than as terminal output.
