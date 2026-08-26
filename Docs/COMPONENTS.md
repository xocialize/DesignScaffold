# DesignScaffold components — the fleet catalog

**Generated from `Package.swift` by `Tools/generate-components-catalog.py` — do not hand-edit.**
Current release: **0.5.0** · `https://github.com/xocialize/DesignScaffold` (public, MIT).

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

## Candidates — observed, not yet settled

| Candidate | Origin | Status |
|---|---|---|
| **ChipRow** — capsule filter chips, single-select | ML[X] LTX Studio | Observed 2026-08-22, shape not settled. Mentioned on AB-A-0017 for awareness; no ask filed yet. **If you need this too, say so — a second independent need is what moves it.** |
| **Timeline T2** — drag, cross-track move, edge trim, snapping (pluggable sources), **plus a trackpad scroll catcher** (horizontal two-finger scrub + pinch-zoom → geometry; vertical track scrolling stays app-side) | AB-A-0031 | Scope confirmed. **Deliberately gated** on ML[X] LTX Studio taking T1 into real use and reporting what the shape gets wrong — their call and the right order. Tracked as AB-T-0088. |
| **Timeline T3** — in/out brackets, gap indicators, marquee select, row-height resize | AB-A-0031 | Scope confirmed 2026-08-26: the scaffold draws **that** a gap exists (the lane knows where clips are not); the consumer decorates it with its own affordance and click target. |

## Migration notes

Adopting a token sometimes changes what pairs with it. Notes earned by real migrations:

| Token | Watch for |
|---|---|
| `Color.selectionWash` | It is a **15% wash, not a solid fill**. Content keeps its normal `label`/`secondaryLabel` colours. Migrating from a solid selection colour (e.g. `#094771`) means the hardcoded `Color.white` that solid required goes illegible — MLXEngineUI hit exactly this on a selected sidebar row, caught only by rendering the real view. White-on-accent stays correct for a *solid* accent fill (prominent buttons, a selected calendar day). |
| `Color.fieldFill` | `textBackgroundColor` sits **darker in dark mode** than a hand-picked elevated well (e.g. `#2D2D2D`). That is adaptation working. If a genuinely raised well is wanted, that is `Color.fillElevated`. |
| `Color.fillElevated` | A derived `label @ 8%` composite, so it reads as raised on any surface — but it is *subtle by design*. If you need a hard-edged chip, add a `separator` border rather than reaching for a heavier fill. |
| `TimelineTheme.selection` | Defaults to the system accent, while the playhead is red — a user whose accent is **red or orange** gets selection chrome that reads as a playhead. On a precision editing surface, pin it: `theme.selection = Tokens.Color.accentFigma`. The library keeps the semantic default; the collision is app-specific. |
| Any hardcoded literal | Replacing hex with a semantic changes light mode the most, because that is where the hardcoded value was never right. Render both appearances: **dark is the control** — if dark shifts more than your geometry deltas predict, something forwarded wrong. |

## Who has adopted

Detected by `Tools/scan-adopters.py`, never announced — a hand-kept list rots (ours once
claimed an adopter that had quietly forked the vocabulary instead). Ground truth is a
source `import`; the pin column shows version drift.

<!-- Generated by Tools/scan-adopters.py — do not hand-edit. Release 0.5.0. -->

| Adopter | Project | Products used | Files | Pin | |
|---|---|---|---|---|---|
| **ML[X] Audio Studio** | ml(x) | `DesignScaffold` | 2 | 0.4.2 | ⚠️ 0.5.0 available |
| **ML[X] LTX Studio** | ml(x) | `DesignScaffold`, `DesignScaffoldLoading`, `DesignScaffoldStageStepper` | 5 | 0.4.0 | ⚠️ 0.5.0 available |
| **ML[X] Media Optimizer** | ml(x) | `DesignScaffold` | 3 | 0.2.0 | ⚠️ 0.5.0 available |
| **mlx-engine-swift** | MLXEngine | `DesignScaffold` | 5 | 0.4.2 | ⚠️ 0.5.0 available |

**Linked but unused** (a pin with no import — dead dependency): `ML[X]-MediaForge`, `sensenova-u1-swift`

### ⚠️ Vocabulary forks — a second design authority in the making

A local `enum Tokens` outside this package. Per AB-D-0042 these should adopt
the package; anything genuinely missing gets added to `Tokens` here by ask.

| Where | Project | File | Lines |
|---|---|---|---|
| Audio8 Demo | mlxengine-audio | `mlxengine-audio/PROD/Audio8/Audio8 Demo/Audio8 Demo/Design/DesignTokens.swift` | 202 |
| Moebius Demo | mlxengine-image | `mlxengine-image/PROD/Moebius/Moebius Demo/Moebius Demo/UI/Tokens.swift` | 202 |
| fleetlock-selfservice | MVSCollective | `MVSCollective/Fleetlock/agent/fleetlock-selfservice/Sources/FleetLockSelfService/DesignTokens.swift` | 58 |
