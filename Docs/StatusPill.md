# Status Pill

A dot, a label, a capsule. Reports what something is doing.

```swift
import DesignScaffoldStatus

StatusPill("Ready · q4", status: .ready)
StatusPill("Preparing…", status: .working())
StatusPill("Streaming", status: .working(elapsed: seconds))   // → "Streaming — 4.0 s"
StatusPill("Failed", status: .failed)
StatusPill("Offline — playing cache", status: .degraded)
StatusPill("Choose a models folder", status: .attention)
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

## `degraded` — working, but not on the good path

Added in 0.20.0, promoted from two independent needs that both had to say it without help:

- **MarqueeSurface**'s connection state has an `.offline` meaning *amber, still playing* —
  last-known-good cached content, explicitly neither idle nor failed. `ready` lies green,
  `failed` lies dead, `idle` loses the amber, so it kept an app-composed pill and filed
  AB-A-0042 rather than inventing one.
- **ModelSheetStudio** independently grew `Availability.degraded(whyNot:fallback:)`, which
  reports `isUsable: true` and renders amber. Same semantic, unrelated domain.

⚠️ **It does not pulse.** Degraded is a *settled* state — the system is not working toward
anything, it has arrived somewhere worse. A pulse says "hold on"; the honest message is "this
is how it is now".

⚠️ **It does not borrow `working`'s orange.** `Tokens.Color.degraded` is yellow — the classic
health middle of green / yellow / red. Sharing orange would leave the pulse as the only
difference between "in flight" and "degraded", and a pulse is precisely what is lost in a
still screenshot, a support ticket, or a glance — which are exactly the moments someone asks
"is this working or broken?".

**Any reason belongs in the label**, which the host owns. ModelSheetStudio's
`whyNot`/`fallback` payload feeds a tooltip rather than the badge text, which is why the case
carries nothing.

### ⚠️ Source-breaking for exhaustive switches

Adding an enum case breaks any `switch` over `Status` without a `default`. Consumers that only
*construct* a `Status` and hand it to `StatusPill` — which is all of them today — are
unaffected.

## `attention` — settled, and waiting on a person

Added in 0.23.0. Not usable until someone acts; nothing went wrong. A folder to choose,
weights to download, a Character to re-bake.

Promoted from three apps that had each bent a different case to say it:

- **ML[X] Audio Studio** (AB-A-0060) rendered an `invalidated` Character's pill as `.failed`
  — red, the only element in the view disagreeing with the three amber ones beside it — and
  asked rather than widening `degraded` on their own.
- **Audio8 Demo** mapped `needsFolder` / `needsDownload` to `.working()`, because grey read as
  settled and nothing amber held still. So a state waiting on the *user* pulsed "hold on" at
  them indefinitely.
- **ModelSheetStudio** draws `availableAfterEvict` amber with a badge glyph.

**Why not `degraded`?** Both of its promotions were usable-on-a-fallback (`isUsable: true`).
Widening it would make "can I use this?" unanswerable from the state. The doc comments on both
cases now point at each other.

⚠️ **Told apart by shape, not colour.** It shares `working`'s amber — the conventional
"needs attention" hue — so the pill draws a badge glyph (`exclamationmark.circle.fill`,
`StatusPillTheme.attentionSymbol`) *instead of* the dot, as two of the three sources already
did. That keeps the bar set for `degraded`: a still screenshot can tell it from an in-flight
state without needing the pulse.

It does not pulse.
