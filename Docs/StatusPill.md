# Status Pill

A dot, a label, a capsule. Reports what something is doing.

```swift
import DesignScaffoldStatus

StatusPill("Ready · q4", status: .ready)
StatusPill("Preparing…", status: .working())
StatusPill("Streaming", status: .working(elapsed: seconds))   // → "Streaming — 4.0 s"
StatusPill("Failed", status: .failed)
```

## Promoted from eight copies

The fleet's most-duplicated UI atom, found by a survey rather than proposed:

| where |
|---|
| ModelSheetStudio `DesignKit/Atoms.swift` |
| ML[X] Media Forge `ForgeUI/Components/Atoms.swift` — **byte-identical to the above** |
| ModelSheetStudio `DesignSpike/Atoms.swift` |
| MLX MageVL Demo `UI/RootView.swift` |
| Nemotron ASR Demo `UI/Theme.swift` |
| Qwen Image Demo `UI/Theme.swift` |
| LLM Voice Chat `UI/Theme.swift` |
| ML[X] Audio Studio `UI/RootView.swift` |

Two are byte-identical, which means one was copied from the other and neither knew. They agreed
on nearly everything — a 6pt dot, ~6pt gap, caption text, 4pt vertical padding, a capsule on an
elevated fill — so the shape here is theirs. Where they disagreed is the reason the component
exists.

## ⚠️ Status-driven, not colour-driven

Four of the eight took a `Color` from the call site. That puts the semantic decision at every
use, which is how a fleet acquires several greens that all mean "ready". Here the status picks
its colour from `Tokens.Color.ready` / `.working` / `.failure` — which is what those tokens were
added for, and what the token file's own comment already anticipated.

The **label** stays yours. Every copy composed its own — `"Ready · \(quant)"`,
`"Download needed"`, `"Streaming"` — and that is app vocabulary, not design vocabulary. A
tooltip is yours too: apply `.help(_:)` as MageVL's copy does.

## ⚠️ One pulse rhythm

ML[X] Audio Studio's pill breathed at 0.6s to 0.3 opacity; `StageStepper` shipped at 0.9s to
0.15. Two rhythms for one idea — "work is in flight" — in two windows a user may have open at
once. Both now read `Tokens.Motion`, and a test asserts they stay equal.

**Only `working` pulses.** A pulse means "this is still going"; attaching it to a settled state
is a lie the user learns to ignore, which costs the pulse its meaning everywhere.

⚠️ **The pulse is keyed on the STATUS, not on `onAppear`.** A host normally binds one pill to a
changing value, so the view updates in place and is never rebuilt — an `onAppear`-only pulse
would simply never start. Verified in the Component Lab by toggling a live pill in place and
watching the dot begin to breathe and the readout tick.

## Reduce Motion

The dot holds a steady, slightly-faded opacity rather than full. Not full, deliberately: it must
still read as **active** when it cannot breathe, and a pulse that simply stops is
indistinguishable from one that finished.

## Live seconds

`.working(elapsed:)` appends a one-decimal readout, rendered `.monospacedDigit()` — live numbers
in proportional digits jitter as they tick, and the movement reads as instability in the thing
being measured rather than in the label. A negative elapsed is clamped to zero, because a host
subtracting timestamps across a pause should not render `-0.4 s`.
