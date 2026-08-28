# Tools

## `InputDriver` — drive a component under a real pointer

Every defect found in `DesignScaffoldTimeline` after it compiled was found by a pointer, and
none by anything headless. This exists so that verification does not depend on a human
clicking.

```bash
cd Tools/InputDriver && swift build -c release
D=.build/release/inputdriver

$D trust                       # refuses loudly rather than posting into the void
$D windows menutest            # window bounds in the SAME top-left space CGEvent uses
$D activate menutest           # REQUIRED first — see below
$D click 3759 652
$D rightclick 3759 652
$D drag 3759 652 3900 652 24
```

Adapted from ML[X] LTX Studio's `Tools/drag.swift` (AB-A-0031). Four things make synthetic
input actually register; each of them silently produces "the app ignored it" when missing,
and three of them cost me a wrong conclusion before they were understood:

1. **A real `CGEventSource`.** SwiftUI reads the source's button state; events posted with a
   nil source arrive as moves with no button held. *(Their finding.)*
2. **`mouseEventClickState` on down/drag/up.** Without it a click is not a click. *(Their
   finding — I had this missing, which is why an earlier harness was inert.)*
3. **Accessibility trust.** `CGEvent.post` to the HID tap is a silent no-op for an untrusted
   process. `inputdriver` refuses to run rather than post into the void — an untrusted
   harness reports a bug that does not exist.
4. **Activate first, and expect the first click to be swallowed.** A click into a background
   window is consumed activating it. Measured: after `activate`, the first click registers
   nothing and subsequent clicks land correctly. Always activate, then discard one click.

A double-click is ONE pair with `clickState` 2 — AppKit reads the state field, not the
interval, so two fast clicks are two single clicks however fast they arrive.

## `DrawnFrameProbe` — click what was drawn, never what you computed

Do not compute click targets by hand. Two false defect reports in this project came from
coordinate conversion, one on each side of the fleet, and a third was reproduced here on
purpose while proving the point.

Have the view report its own frame and click *that*:

```swift
Color.blue.frame(width: w, height: h)
    .drawnFrameProbe("clip-A")     // prints: PROBE clip-A centre=(3759,652) size=144x56
```

Two rules it encodes, both learned the hard way:

- **SwiftUI's `.global` space is window-FRAME relative, not content-view relative.** Adding
  the title bar again puts every target ~27–34pt too low. *(Their correction; reproduced
  here by estimating a target by hand and landing exactly 27pt low.)*
- **Re-report on change, not just `onAppear`.** A frame recorded once goes stale the moment
  an edit resizes the element, and a harness clicking a stale centre lands on a trim handle
  and blames the component.

The probe must never intercept a hit — `allowsHitTesting(false)`, always. A probe that
swallowed clicks would be a hit-testing bug inside the hit-testing harness.

## Others

- `generate-components-catalog.py` — regenerates `Docs/COMPONENTS.md` from `Package.swift`.
  Run it in the same change that ships a component.
- `scan-adopters.py` — detects adoption (imports are ground truth), pin drift, dead pins and
  vocabulary forks. Sanctioned exceptions carry their reason inline rather than being
  re-flagged forever.
