# Hit-test probe

The pointer gate: report where a view was **drawn**, and what a gesture actually **did**.

```swift
import DesignScaffoldProbe

ClipView(clip)
    .hitTestProbe("clip-\(clip.id)")
```

Run the app with `-DesignScaffoldProbe YES` (or `DESIGNSCAFFOLD_PROBE=1` in the environment),
then drive it with [`Tools/InputDriver`](../Tools/README.md) at the reported coordinates:

```
PROBE TARGET clip-A centre 3800 519 size 144x56
PROBE READY 11
```

Everything is inert unless enabled, so a `.hitTestProbe(_:)` is safe to leave at a call site.

## Why it is a product

Every defect this library shipped **after it compiled** was found by a pointer, and none by a
headless test. Renders prove placement; unit tests prove arithmetic; neither reaches hit
testing or gesture lifetime.

Two apps had already written this independently — ML[X] LTX Studio's `HitTestProbe` and
DesignWorkspace's `DrawnFrameProbe` — and each had learned something the other had not. This is
the union:

| from | what it contributes |
|---|---|
| LTX Studio | **coalescing** — SwiftUI reports geometry repeatedly during layout, so one settled flush beats fifty lines in flight |
| LTX Studio | **outcome reports** — `selection`, `activation`, `menuItem`, `commit`. Coordinates alone cannot close a gate |
| DesignWorkspace | the **`ViewModifier`** — one line at a call site instead of a hand-written `GeometryReader` overlay at each |
| DesignWorkspace | **no non-zero guard** — see below |
| both | the window-**FRAME** conversion, which both got wrong first |

## Three rules it encodes, each from a wrong answer

⚠️ **Take the click target from the DRAWING, never from geometry you compute.** The bug class is
"what is drawn and what is hit disagree", so a probe that derived its own rect would agree with
the bug.

⚠️ **`.global` is the window FRAME, not the content view.** Converting through
`contentView.bounds` puts every target exactly one title bar (~27–34pt) too low. Both apps hit
this; a target estimated by hand landed 27pt off for the same reason and produced a false
defect report.

⚠️ **A zero is a measurement.** An earlier version skipped empty frames, so a view that
collapsed to zero never reported again and the probe kept serving its last non-zero size — a
correctly-collapsed pane read as one that had ignored its frame. Measured against
`WorkspaceSplit`, where the arithmetic said `0` and the probe insisted on `103`.

## Outcomes, not just coordinates

"The click landed" and "the right thing happened" are different questions, and the second
catches the gesture that previews correctly and commits nothing:

```swift
HitTestProbe.selection(selectedIDs.map(String.init))
HitTestProbe.menuItem("Delete", on: clip.name)
HitTestProbe.commit("trim", clip.name, "start 1.00 duration 2.40")
```

⚠️ From outside an app, a right-click that opens **nothing** and one that opens the **wrong**
menu look identical. DesignScaffold 0.8.3 was exactly a menu that stopped presenting in one
selection state while every screenshot of the other state looked perfect.

## Routing the output

`HitTestProbe.emit` defaults to stdout, which is what a shell harness reads. An app with its
own logging replaces it — ML[X] LTX Studio routes its probe through `OSLog`, and losing that
would have been a reason not to adopt.

## The other half

The probe reports coordinates; something has to click them. `Tools/InputDriver` posts real
`CGEvent`s, and `Tools/README.md` carries the four rules that make synthetic input register —
including that a click into a window which is not frontmost is consumed activating it.
`Tools/menu-matrix.sh` is a worked example that walks a behaviour matrix with a positive
control on every cell.
