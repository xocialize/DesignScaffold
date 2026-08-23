# DesignScaffold components — the fleet catalog

**Generated from `Package.swift` by `Tools/generate-components-catalog.py` — do not hand-edit.**
Current release: **0.4.0** · `https://github.com/xocialize/DesignScaffold` (public, MIT).

> **Before building any macOS UI surface, look here first.** DesignScaffold is the fleet's
> single design authority (AB-D-0040 / AB-D-0041): the token vocabulary and every shared
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
| Engine-management panels — settings, model storage, model state | **MLXEngineUI** (should consume DesignScaffold tokens — AB-A-0018) |
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
