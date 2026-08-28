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
- **Controls under a driver are buttons, not toggles or segmented pickers.** A probe reports a
  labelled `Toggle`'s whole rect, and its centre falls in the gap between text and switch,
  where a click lands on nothing.
- **Activate immediately before every synthetic click.** A click into a window that is not
  frontmost is consumed activating it.

## Harnesses

| id | what it is for |
|---|---|
| `timeline-menu` | Which context menu wins, across every combination. `Tools/menu-matrix.sh` drives it. |
| `timeline` | Drag, cross-track, trim, marquee, brackets, row resize — the T2/T3 gestures. |
| `chips` | Wrapped `ChipRow` clickability, which no render or unit test can reach. |
| `playlist` | Drag-reorder and selection. |

Add one by dropping a file in `ComponentLab/Harnesses/` — the target uses a synchronised file
group, so no project edit is needed — and adding a row to `ComponentLabView.harnesses`.
