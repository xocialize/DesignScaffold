# DesignScaffold components — the fleet catalog

**Generated from `Package.swift` by `Tools/generate-components-catalog.py` — do not hand-edit.**
Current release: **0.15.0** · `https://github.com/xocialize/DesignScaffold` (public, MIT).

> **Before building any macOS UI surface, look here first.** DesignScaffold is the fleet's
> single design authority (AB-D-0040 / AB-D-0042): the token vocabulary and every shared
> component live here, so apps stop re-deriving spacing, radii, and type by eye. If what you
> need is listed, adopt it. If it is close but not right, ask for the change. If it does not
> exist and more than one app would use it, propose it.

## Available now

| Library product | What it is |
|---|---|
| `DesignScaffold` | The design vocabulary itself: Tokens (colour · type · spacing · radii · layout) + cardSurface(). Zero dependencies; every component product re-exports it |
| [DesignScaffoldCalendar](Calendar.md) | Month calendar (single/multiple/range selection) in the scaffold house style |
| [DesignScaffoldPlaylist](PlaylistIterator.md) | Sortable playlist list (thumbnail · name · metadata, drag-reorder, active marker) |
| [DesignScaffoldLoading](LoadingModal.md) | Model/product loading modal (hero percentage · status · detail fields · bar) |
| [DesignScaffoldStageStepper](StageStepper.md) | Run-progress stepper for multi-phase operations (planned nodes · pulse · counters) |
| [DesignScaffoldTimeline](Timeline.md) | Media-agnostic multi-track timeline (ruler · headers · clip lanes · playhead) |
| `DesignScaffoldChips` | Capsule filter chips, single-select, wrapping |
| `DesignScaffoldWorkspace` | Three-panel app shell (navigation rail · work area · inspector) with hairlines |
| `DesignScaffoldProbe` | Opt-in pointer gate: report where a view DREW, and what a gesture actually did |
| `DesignScaffoldPicker` | Findable selection list for large libraries (search · tag scoping · sort · multi-select) |
| `DesignScaffoldStatus` | Status pill: a dot, a label, a capsule — idle · working · ready · failed |
| [DesignScaffoldWaveform](Waveform.md) | Audio waveform: a live input level meter and a track visualiser, one Canvas renderer |
| `DesignScaffoldMetrics` | Metric tile and grid: one headline measurement — value · unit · label · caption |

Every component product re-exports `DesignScaffold`, so one import brings `Tokens` and
`cardSurface()` along. Each wears the scaffold look **by default** — no theme call at the
call site — and exposes a `*Theme` whose initializer defaults are the token values, so a
custom theme that only overrides colours still inherits the scaffold geometry.

## Adopting

```swift
// Package.swift
.package(url: "https://github.com/xocialize/DesignScaffold.git", from: "0.1.0")
// then select ONLY the products you use, e.g.
.product(name: "DesignScaffoldStageStepper", package: "DesignScaffold")
```

In Xcode: *File ▸ Add Package Dependencies…*, paste the URL, and tick the libraries you
want. Pin to the tag; `from:` picks up later releases automatically.

**The house rule travels with the tokens:** no view hardcodes a colour, font size, or
spacing value. If a value you need is missing, it gets **added to `Tokens` here first**
(by ask) rather than invented locally — that constraint is what keeps a Figma refresh a
one-file change instead of a fleet-wide hunt.

## Where the boundary sits

| Layer | Source |
|---|---|
| Design vocabulary — colour, type, spacing, radii, `cardSurface()` | **DesignScaffold** (authoritative) |
| Shared components — calendar, playlist, loading, stepper | **DesignScaffold** |
| Engine-management panels — settings, model storage, model state | **MLXEngineUI** (conforming to these tokens — AB-A-0019) |
| App-specific product UI (chat views, editors, composites) | the app |

## Requesting a component

Open a bridge ask to the `DesignScaffold` area:

```
bridge ask --to DesignScaffold --title "Propose <Name> into DesignScaffold" --body "..."
```

The intake bar — all four of these, drawn from the accepted AB-A-0017:

1. **The shape has settled** — it survived repeated real use, not one screen.
2. **It is already data-driven and dependency-free** — no engine, model, or app types in
   the view; hosts pass values in. Correlation/formatting stays app-side.
3. **No new tokens needed** — or say exactly which are missing, and they get added here.
4. **There is a written contract to generalise against** — measured behaviour beats a
   description of the pixels.

A fifth signal short-circuits debate: **two independent apps want it.** If a candidate
below matches something you need, say so on its ask — that is the strongest evidence there is.

**Two independent *surfaces* can substitute for two apps** when the component's values are
already derived from this area's tokens or artboards (AB-D-0049). Recurrence proves the shape
has settled; authority-derived values cover the idiosyncrasy risk that a second app would
otherwise cover. Recurrence itself is not negotiable — a single surface, however well
specified, is not yet a component.

## Candidates — observed, not yet settled

| Candidate | Origin | Status |
|---|---|---|
| _none open_ | | ChipRow graduated to `DesignScaffoldChips` in 0.8.0 (AB-A-0032). Propose a component with a bridge ask to the `design-scaffold` area — the intake bar is in COMPONENTS.md. |

## Migration notes

Adopting a token sometimes changes what pairs with it. Notes earned by real migrations:

| Token | Watch for |
|---|---|
| `Color.selectionWash` | It is a **15% wash, not a solid fill**. Content keeps its normal `label`/`secondaryLabel` colours. Migrating from a solid selection colour (e.g. `#094771`) means the hardcoded `Color.white` that solid required goes illegible — MLXEngineUI hit exactly this on a selected sidebar row, caught only by rendering the real view. White-on-accent stays correct for a *solid* accent fill (prominent buttons, a selected calendar day). |
| `Color.fieldFill` | `textBackgroundColor` sits **darker in dark mode** than a hand-picked elevated well (e.g. `#2D2D2D`). That is adaptation working. If a genuinely raised well is wanted, that is `Color.fillElevated`. |
| `Color.fillElevated` | A derived `label @ 8%` composite, so it reads as raised on any surface — but it is *subtle by design*. If you need a hard-edged chip, add a `separator` border rather than reaching for a heavier fill. |
| `TimelineTheme.selection` | Defaults to the system accent, while the playhead is red — a user whose accent is **red or orange** gets selection chrome that reads as a playhead. On a precision editing surface, pin it: `theme.selection = Tokens.Color.accentFigma`. The library keeps the semantic default; the collision is app-specific. |
| `TimelineTrack` **0.5.0 → 0.6.0** | Now generic over its ID (`TimelineTrack<UUID>`), so a UUID-keyed document no longer round-trips through `uuidString` on the way in and `UUID(uuidString:)` on the way back out — a stringly-typed seam that failed silently if a parse ever went wrong. Call sites usually infer (`TimelineTrack(id: uuid, …)`, `controls: [.mute]`); only explicit annotations need the parameter, as `TimelineTrack<UUID>.Control`. Existing String-keyed code compiles unchanged. |
| Any hardcoded literal | Replacing hex with a semantic changes light mode the most, because that is where the hardcoded value was never right. Render both appearances: **dark is the control** — if dark shifts more than your geometry deltas predict, something forwarded wrong. |

## Who has adopted

Detected by `Tools/scan-adopters.py`, never announced — a hand-kept list rots (ours once
claimed an adopter that had quietly forked the vocabulary instead). Ground truth is a
source `import`; the pin column shows version drift.

<!-- Generated by Tools/scan-adopters.py — do not hand-edit. Release 0.8.1. -->

| Adopter | Project | Products used | Files | Pin | |
|---|---|---|---|---|---|
| **ML[X] Audio Studio** | ml(x) | `DesignScaffold` | 2 | 0.4.2 | behind (0.8.1) |
| **ML[X] LTX Studio** | ml(x) | `DesignScaffold`, `DesignScaffoldChips`, `DesignScaffoldLoading`, `DesignScaffoldStageStepper`, `DesignScaffoldTimeline` | 10 | 0.8.1 | ✅ |
| **ML[X] Media Optimizer** | ml(x) | `DesignScaffold` | 3 | 0.2.0 | behind (0.8.1) |
| **SenseNova-U1.5 Demo** | Demos | `DesignScaffold` | 7 | 0.6.0 | behind (0.8.1) |
| **mlx-engine-swift** | MLXEngine | `DesignScaffold` | 5 | 0.4.2 | behind (0.8.1) |

**Linked but unused** (a pin with no import — dead dependency): `sensenova-u1-swift`

_A version behind the latest is a resolved snapshot, not a defect: no adopter declares an exact pin, so every one moves forward on its next resolve._

### ⚠️ Vocabulary forks — a second design authority in the making

A local `enum Tokens` outside this package. Per AB-D-0042 these should adopt
the package; anything genuinely missing gets added to `Tokens` here by ask.

| Where | Project | File | Lines |
|---|---|---|---|
| Audio8 Demo | mlxengine-audio | `mlxengine-audio/PROD/Audio8/Audio8 Demo/Audio8 Demo/Design/DesignTokens.swift` | 202 |
| Moebius Demo | mlxengine-image | `mlxengine-image/PROD/Moebius/Moebius Demo/Moebius Demo/UI/Tokens.swift` | 202 |

### Sanctioned — not ours, and deliberately not flagged

- **fleetlock-selfservice** (`MVSCollective/Fleetlock/agent/fleetlock-selfservice/Sources/FleetLockSelfService/DesignTokens.swift`) — A different product's design system, not a copy of ours: a 1:1 mapping of the Figma file `hz46ViMGoMIpwBUKnjZhrQ` ("FleetLock Self-Service"), hex copied from that source, on the off-corpus volume. AB-D-0042 governs this fleet's macOS apps; it does not reach another product with its own design authority. (AB-T-0087)
