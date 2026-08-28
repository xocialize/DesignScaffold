# DesignWorkspace — the Component Lab

A real AppKit app that hosts every DesignScaffold component, so behaviour can be verified
where it ships.

```bash
xcodebuild -project DesignWorkspace/DesignWorkspace.xcodeproj -scheme DesignWorkspace \
  -configuration Debug -destination 'platform=macOS' build
open -a "$(pwd)/…/DesignWorkspace.app" --args -ComponentLab
```

`-ComponentLab` opens the lab instead of the workspace app's Metal preview pipeline; without
it nothing changes. The package is consumed by **local path**, so the lab always exercises the
working tree, not a tag.

## Why it exists

Every defect found in a DesignScaffold component after it compiled was found by a pointer, and
none by a headless test. Renders prove placement; unit tests prove arithmetic; neither touches
hit testing or gesture lifetime, which is where this library has actually broken — eight times.

A scratchpad `NSHostingView` is not enough either. A consumer's context-menu report was chased
for two days across two wrong explanations, both produced by scratchpad harnesses that
disagreed with a shipping app. `Tools/menu-matrix.sh` settled it in one run here.

## The rules the harnesses encode

- **A null result needs a live positive control in the same burst.** Every menu cell also
  right-clicks the gap, whose menu must open. A cell whose control is dead is INCONCLUSIVE,
  never evidence.
- **Name captures from what the app printed, not from the loop variable.** A control click
  that misses leaves the driver confident and every later file mislabelled — which happened on
  the first matrix run, and the `STATE` line is the fix.
- **Click probe-reported coordinates, never computed ones.** `drawnFrameProbe` reports where a
  view was *drawn*, in the top-left space `CGEvent` uses. Estimating a target by hand has
  already landed 27pt off and produced a false defect report.
- **A drawn rect is an upper bound on the hit rect, not the hit rect.** SwiftUI hit tests what
  a view DREW, so padding, a `.background`, and the empty space in a stack all sit inside the
  reported frame and outside the target. Measured here: a sidebar row reported y 609…657 while
  only **632…650** answered a click, and a labelled `Toggle`'s reported centre landed in the
  dead gap between its text and its switch. Give anything a driver clicks an explicit
  `.contentShape(Rectangle())`; the probe cannot tell you the two rects differ, only a click
  can. With the shape added, that row's band became 610…657 — the probe's rect exactly.
- **Controls under a driver are buttons, not toggles or segmented pickers.** One probed rect,
  one click, no arithmetic about which third of a picker to hit.
- **Activate immediately before every synthetic click.** A click into a window that is not
  frontmost is consumed activating it.

## Harnesses

| id | what it is for |
|---|---|
| `timeline-menu` | Which context menu wins, across every combination. `Tools/menu-matrix.sh` drives it. |
| `timeline` | Drag, cross-track, trim, marquee, brackets, row resize — the T2/T3 gestures. |
| `chips` | Wrapped `ChipRow` clickability, which no render or unit test can reach. |
| `playlist` | Drag-reorder and selection. |

## Launch flags

| flag | what it does |
|---|---|
| `-ComponentLab` | the harness gallery |
| `-MenuProbe` | `Tools/MenuPrecedenceProbe.swift`, the copy handed to consumers — dogfooded here so both sides run identical source |
| `-MainMenu` | installs a hand-built menu bar transcribed from a consumer's `AppMenu.swift`, as an experimental variable |

## What it has established so far

- **Context-menu precedence** (`Tools/menu-matrix.sh`, 8 cells, control on each): a
  `.contextMenu` anywhere inside `clipBody` wins; `.clipContextMenu` answers only when the
  host's body has none. This **refuted** the shipped doc claim that a clip body must be
  "hit-testable" for its own menu to present — measured with an opaque gradient, a greedy
  frame, under an `allowsHitTesting(false)` overlay, and with a consumer's body transcribed
  verbatim. See AB-A-0031, AB-L-0066.
- **A wrapped `ChipRow` is clickable on every row.** Chips on rows 1, 2 and 3 of a 240pt-wide
  row each registered as themselves — `ChipFlowLayout` places hit regions where it draws.
- **`PlaylistIterator` drag-reorder commits correctly under a synthetic driver**: dragging
  row 1 onto row 3 committed `2,3,1,4,5`, once.

Add one by dropping a file in `ComponentLab/Harnesses/` — the target uses a synchronised file
group, so no project edit is needed — and adding a row to `ComponentLabView.harnesses`.
