# Hit-test probe

The pointer gate: report where a view was **drawn**, and what a gesture actually **did**.

```swift
import DesignScaffoldProbe

ClipView(clip)
    .hitTestProbe("clip-\(clip.id)")
```

Run the app with `DESIGNSCAFFOLD_PROBE=1` in the environment (the `-DesignScaffoldProbe YES`
argument also works in a bundled app, but it stopped a SwiftPM app's window from appearing,
AB-L-0150), then drive it with [`Tools/InputDriver`](../Tools/README.md), or with AppProbe's
`pointer` tool, at the reported coordinates:

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

## The channel: state, commands, events, stalls (0.26.0)

Coordinates and outcome lines answer "where" and "did it fire". A checklist also asks what the
app now **holds** ("a Generative Layer above the active layer, masked by the selection"), needs
input the pointer can't give politely (a stroke on a canvas while the operator keeps working),
and asks whether the app **stayed responsive**. 0.26.0 adds those, through one invisible
element a driver reaches over accessibility:

```swift
RootView()
    .designScaffoldProbeHost()            // once per window; HitTestProbe.installHost(in:) for AppKit

HitTestProbe.state("document") {         // computed at read time, never stale
    ["size": [doc.width, doc.height], "layers": doc.layers.map(\.name),
     "undo": undoManager.undoActionName, "selection": selection?.bounds]
}
HitTestProbe.command("canvas.drag") { args in   // runs on the main thread when a driver sets it
    try ProbeInput.drag(canvas, from: canvas.viewPoint(try args.point("from")),
                                to: canvas.viewPoint(try args.point("to")))
    return ["layers": doc.layers.count]
}
HitTestProbe.event("EXPORTED", url.lastPathComponent)   // numbered with SELECTION, COMMIT…
```

**The wire.** The host is a 1 × 1 view with the accessibility identifier `DesignScaffoldProbe`:
- **Read its AX value** to get JSON: `targets` (as `PROBE TARGET` prints them), `state` (every provider, run now), `last_seq`, the `commands` it takes, `heartbeat`, and the last command's `reply`.
- **Set its AX value** to `{"id": "…", "command": "name", "args": {…}}` to run a command. Its reply (`ok`, and `result` or `error`) comes back on the next read, under the same `id`.
- **Built-in commands:** `events {since: seq}` returns the numbered events after a seq. `ping` checks the wire.

Accessibility, not a socket, because:
- a driver already speaks it;
- a sandboxed app needs no entitlement for it, where a socket or a loopback port would;
- it reaches an app however it was launched, Xcode included, where stdout isn't the driver's to read.

Everything is absent from the accessibility tree unless the probe is enabled.

**`ProbeInput`** sends real `NSEvent`s straight to an **AppKit** view's `mouseDown`, `mouseDragged` and `mouseUp`, as an app's hosted tests do. No pointer moves and the app needn't be in front.

⚠️ It tests what the view **does** with a press, not whether a press would **reach** it. Window hit testing, a sheet in the way and first-click activation are all skipped; checking those is the real pointer's job. And a SwiftUI gesture ignores it: this harness measured `NSApp.sendEvent` and direct `mouseDown` inert there. Use `.hitTestProbe` targets and the real pointer for SwiftUI.

**The heartbeat.** While the channel runs, a background timer asks the main queue to note the time every 50 ms. An answer more than 100 ms late is a **stall**, kept with its start (the app's uptime clock, which events also carry) and length. One blocked stretch counts once, not once per delayed beat.

A driver can't read the app *during* a stall, because its accessibility requests wait for the same main thread. So the stalls are kept and read afterwards. "The app stays responsive while it runs" becomes the worst stall since the run started.

**Driving it.** AppProbe (`xocialize/AppProbe`, the `appprobe` MCP server) reads and commands the host:
- `probe` lists targets, commands, state names, events since a seq and the worst stall;
- `probe_state` returns the state and the stalls since a moment;
- `probe_command` runs a command and returns its result, with the seq before it ran.

`pointer target=` clicks a probe target with the real pointer. It refuses to click when another app's window is on top at that point (AB-L-0150).

