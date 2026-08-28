# Workspace Split

The fleet's three-panel app shell — navigation rail · work area · inspector — with the
hairlines built in.

```swift
import DesignScaffoldWorkspace

WorkspaceSplit {
    ScreenRail(model: model)
} center: {
    PreviewStage()
} trailing: {
    Inspector(model: model)
}
.paneWidths(leading: 350, trailing: 300)
```

Two panes, for a shell with no inspector:

```swift
WorkspaceSplit {
    Sidebar()
} center: {
    Detail()
}
```

## Why it exists

Four apps had written this independently before it was a component:

| shell | leading | center | trailing |
|---|---|---|---|
| MarqueeStudio · Screens | 350 | flexible | 300 |
| MarqueeStudio · Editor | 420 | flexible | 360 |
| ML[X] Media Forge · Optimizer | 300 | 800 minimum | 300 |
| DesignWorkspace | 260 | flexible | — |

Four sets of widths is fine — apps differ. What was not fine: two different hairline idioms
(`Rectangle().fill(…).frame(width: 1)` and `Divider().overlay(…)`), each picking its own
colour, and in Media Forge **a doc comment promising "a hairline separator marks its edge"
above a layout that draws none**. The primitive did not exist, so the intent stayed a comment.

None of that is design work. It is the same `HStack(spacing: 0)` retyped, and every copy is a
fresh chance to get the narrow-window behaviour wrong.

## What it fixes that a hand-rolled `HStack` does not

⚠️ **Fixed side panes plus a `maxWidth: .infinity` center means the center absorbs every
shortfall.** Drag the window narrow enough and the work area — the reason the window exists —
reaches zero while both side panes sit at full width. Every hand-rolled shell measured had
this.

`WorkspaceMetrics` honours the center's minimum first, then yields the **trailing** pane before
the leading one: an inspector is the more disposable of the two, and collapsing the navigation
rail first strands the user with content they cannot navigate away from. The arithmetic is a
pure function with unit tests, including the property that the three widths always tile the
available width exactly, swept across every width from 0 to 2000.

## Theming

`WorkspaceSplitTheme` follows the house pattern — initializer defaults are the token values,
`.theme(_:)` overrides, and `.paneWidths(leading:trailing:centerMinimum:)` is the shorthand for
the common case.

⚠️ **`centerFill` defaults to `.clear`, and that is load-bearing.** ML[X] Media Forge mounts an
`NSVisualEffectView` behind this layout and needs the center transparent so the window's
vibrancy shows through. A center painted with a surface colour by default would silently
flatten that.

## Not resizable, deliberately

Every shell measured used fixed widths, so that is what this reproduces. A draggable divider is
a reasonable request — ask for it rather than reaching for `NavigationSplitView`, which renders
an **empty window** inside a `sizingOptions = []` hosting view: measured in DesignWorkspace,
where the content laid out and reported real frames while drawing nothing.

## The hairline itself

`Separator(.horizontal)` / `Separator(.vertical)` live in the base `DesignScaffold` product —
vocabulary, beside `cardSurface()`. Use them anywhere a rule is wanted, not just in a split.

⚠️ A separator is **greedy along its own length**. That is what you want between panes, and a
bug anywhere the parent's height is derived from its children — a greedy vertical rule inflated
a timeline's ruler row and pushed a track out of frame. In an unconstrained context, state the
length: `Separator(.vertical).frame(height: 24)`.
