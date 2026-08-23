# Stage Stepper

`DesignScaffoldStageStepper` — run-progress for a multi-phase operation: dots and a
connecting line for the planned nodes, a pulsing ring on the live one, counters as text,
and an elapsed timer when a node runs long.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="images/stepper-dark.png">
  <img src="images/stepper-light.png" width="760" alt="The stage stepper in four states: plan drawn before the run, mid-run with a pulsing node and counters, a quiet slow node showing an elapsed timer, and the completed run">
</picture>

*The four states: plan drawn before the run · live node with counters · a quiet slow node
proving it is still working · complete.*

Generalised from ML[X] LTX Studio's `RunStepperView`, whose shape held across ~10 measured
generation runs. The behaviour contract below is measured, not designed on paper — see
`mlxengine-video-ltx/LTX_DEV/ltx-2-mlx-swift/docs/UI-RUN-PROGRESS.md`.

## The contract this component encodes

1. **The plan is known up front**, so the connecting line is complete on first paint —
   the node list is not discovered as the run proceeds.
2. **Pulse on event arrival; counters render as text.** Never a percentage synthesised
   across phases: phases are wildly unequal in time (48 fast ticks can pass in one slow
   tick), so a step-counted bar races and then appears frozen. This component exposes no
   overall fraction — deliberately.
3. **The quietest node is often the slowest.** When counters go silent exactly when the
   wait is longest, the honest signals are a continuing pulse, an elapsed timer, and copy
   that sets expectations — see `slowHint`.
4. **Reduce Motion is respected**: the ring holds steady instead of breathing.

## Getting it

Select the `DesignScaffoldStageStepper` library when adding the package. The import
re-exports `DesignScaffold`, so `Tokens` and `cardSurface()` come along.

```swift
import DesignScaffoldStageStepper
```

## Usage

```swift
let plan = [
    StageNode(id: "prompt", title: "Read prompt", detail: "Encoding the prompt"),
    StageNode(id: "generate", title: "Generate", detail: "Denoising"),
    StageNode(id: "decode", title: "Render frames", detail: "Decoding frames",
              slowHint: "this step often takes the longest"),
    StageNode(id: "finish", title: "Finish", detail: "Writing the file"),
]

StageStepper(progress: StageProgress(
    nodes: plan,
    currentIndex: reachedIndex,                   // advance monotonically
    counterText: "step 5 of 8 · pass 1 of 2",     // pre-formatted by the host
    elapsedInNode: Date().timeIntervalSince(nodeEnteredAt)))
```

- `currentIndex` — `nil` before the run (nothing lit); `nodes.count` means **the whole
  run is complete** (every node reads done, nothing live). Advance it monotonically:
  events can arrive out of order or repeat, and a stepper that walks backwards reads as
  a bug.
- `counterText` — the host formats it. A genuinely unknown total must never render as
  zero; omit the counter instead.
- `elapsedInNode` — seconds in the live node. Past the theme's `livenessDelay` (5s) the
  timer appears, with any `slowHint` appended.
- `slowHint` — per-node expectation copy for the slow-and-quiet node.

Wrap the stepper in a `TimelineView(.periodic(from: .now, by: 1))` if you want the
elapsed timer to tick without other state changes.

### Staying engine-free

The component takes `StageNode`s and an index — nothing model- or engine-aware. **Event
correlation stays in the host**, where the engine types live: map your plan to
`StageNode`s, and translate each incoming event to an index (disambiguating a phase that
appears twice, tolerating unknown phases by holding the previous index). That boundary is
what lets one component serve any long-running op — a generation run, a download →
prepare → compile lifecycle, an export pipeline.

### Layout

Horizontal, sized for a wide surface (a run card, a sheet). Allow roughly 90pt per node
so titles are not compressed — six nodes want ~560pt or more.

## Theming

**The scaffold look is the default.** `StageStepperTheme`'s initializer defaults are the
token values, so a custom theme that only overrides colours inherits the scaffold
geometry — including `livenessDelay`, the pulse timing, and the dot/ring metrics.

```swift
var t = StageStepperTheme.scaffold
t.livenessDelay = 10          // quieter: wait longer before showing the timer
StageStepper(progress: progress).theme(t)
```

## Under the hood

`StageProgress`'s display projections — node state derivation, the `nodes.count`
completion sentinel, the liveness threshold, and the VoiceOver phrasing — are pure and
unit-tested. Each node is one accessibility element reading "Step 2 of 6, Generate, in
progress, step 5 of 8".
