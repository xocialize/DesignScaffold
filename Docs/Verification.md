# Verifying a component

Three instruments, in increasing cost and increasing reach. **The cheap ones cannot reach the
defects this library actually ships**, so a component is not done when they pass.

| instrument | proves | cannot touch |
|---|---|---|
| unit tests | arithmetic — packing, snapping, reorder, timecode | anything about a view |
| `NSHostingView` renders | placement, theming, light/dark, wrapping | hit testing, gestures |
| **the Component Lab** + the probe | what a pointer does in a real app | nothing yet |

## Why the first two are not enough

Every defect found in a DesignScaffold component *after it compiled* was found by a pointer,
and none by a headless test. The list is long enough to be a pattern rather than bad luck:
clips that hit-tested at the wrong x, cross-track drags that committed nothing, brackets that
jumped once and stopped, a drag measured in its own moving coordinate space, a chip row whose
clickability nobody had ever checked.

They share a shape: **each one renders perfectly.** A screenshot of a broken hit region is
indistinguishable from a screenshot of a working one.

⚠️ **And a scratchpad `NSHostingView` harness is not a substitute for an app.** It shares the
framework but not the responder chain, the window, or whatever the real call site nests the
component inside. Chasing one consumer's context-menu report through scratchpad harnesses
produced **three** confident mechanisms in a row, all wrong, one of which shipped in this
documentation. A real app answered it in a single run. See [Timeline.md](Timeline.md#clip-context-menus).

## The Component Lab

[`DesignWorkspace`](../DesignWorkspace/README.md) — a real AppKit app in this repo that hosts
every component and consumes the package **by local path**, so it always exercises the working
tree rather than a tag.

```bash
xcodebuild -project DesignWorkspace/DesignWorkspace.xcodeproj -scheme DesignWorkspace \
  -configuration Debug -destination 'platform=macOS' build
```

Launch the built binary with `-ComponentLab`. Add a harness by dropping a file into
`ComponentLab/Harnesses/` — the target uses a synchronised file group, so there is no project
file to edit — and adding a row to `ComponentLabView.harnesses`.

## The probe

[`DesignScaffoldProbe`](HitTestProbe.md) — an **opt-in product**, so an app links it
deliberately and every entry point is inert unless enabled:

```swift
ClipView(clip).hitTestProbe("clip-\(clip.id)")
```

It reports where a view was DRAWN, in the top-left space `CGEvent` uses, plus the outcome
vocabulary a gate needs — `selection`, `activation`, `menuItem`, `commit`. It is the union of
two implementations that grew independently in ML[X] LTX Studio and DesignWorkspace, each of
which had learned something the other had not.

## Driving it

[`Tools/InputDriver`](../Tools/README.md) posts real `CGEvent`s; `Tools/menu-matrix.sh` is a
worked example that walks a whole behaviour matrix and captures every cell.

Four rules, each earned by a run that produced a wrong answer:

1. **Activate immediately before every synthetic click.** A click into a window that is not
   frontmost is consumed activating it, and the result reads as "the feature is broken".
2. **A null result requires a live positive control in the same burst.** In the menu matrix
   every cell also right-clicks a gap, whose menu must open. A cell whose control is dead is
   INCONCLUSIVE — never evidence.
3. **Name evidence from what the app printed, not from the loop variable.** A control click
   that misses leaves the driver confident and every later capture silently mislabelled. The
   lab prints a canonical `STATE` line and the driver refuses to advance when it does not
   change.
4. **Click probe-reported coordinates, never computed ones** — and remember a probe reports
   the **drawn** rect, which is an upper bound on the hit rect. Give anything a driver clicks
   an explicit `.contentShape(Rectangle())`.

## Writing an honest harness

- **Make the result self-identifying.** Each menu item in the matrix names which menu opened,
  so a capture cannot be misread months later. A control that reports "it worked" is worth
  much less than one that reports *which thing* worked.
- **Isolate one variable.** Two switches, four cells, one click point.
- **Attach both candidates and let the winner identify itself** rather than testing them in
  separate runs where the environment can drift.
- **Prefer a control that can report INCONCLUSIVE** over one that can only say pass or fail.
  Unmeasurable must be louder than good.

## What has been established here

- **Context-menu precedence** — a `.contextMenu` inside `clipBody` wins; `clipContextMenu`
  answers only when the body has none. Eight cells, control on each. This refuted a claim that
  had already shipped in these docs.
- **A wrapped `ChipRow` is clickable on every row**, including the third.
- **`PlaylistIterator` drag-reorder commits correctly** under a synthetic drag.
- **A `.plain` `Button`'s hit region is its label's drawn content**, not the padded row — one
  nav row measured 609…657 drawn against 632…650 clickable, which `.contentShape` fixed.
