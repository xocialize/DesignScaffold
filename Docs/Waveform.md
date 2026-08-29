# Audio Waveform

Two surfaces over one renderer: a **live input level meter**, and a **track visualiser** built to
sit inside a timeline clip.

```swift
import DesignScaffoldWaveform

// Live: a rolling window, newest at the right edge.
AudioLevelMeter(levels: capture.levels, isActive: capture.isRecording)
    .frame(height: 32)

// A whole asset, filling whatever frame it is given.
AudioTrackWaveform(peaks: peaks)

// A clip that references a slice of a longer file.
AudioTrackWaveform(peaks: assetPeaks, duration: assetSeconds, visible: clip.sourceRange)
```

The host owns the rolling window; `AudioPeaks.rolling(_:appending:limit:)` maintains it.

## Promoted from two byte-identical copies

LLM Voice Chat and the Nemotron ASR Demo carried the same `WaveformView` — same code, same
comment. Their shape is kept, including the one line that matters most:

> Baseline, so silence still reads as "listening" rather than "broken".

That centre line is drawn **even with no peaks at all**, because a meter showing nothing is
indistinguishable from a meter that is not working.

Two things did not survive the promotion:

⚠️ **The view read the app's buffer constant.** `barWidth = width / MicCapture.levelHistory`
meant the component could not be used by an app whose capture buffer was a different size, and
that buffer silently controlled the visual density. Bar pitch is now a theme value and the
bucketing adapts to the width available.

⚠️ **The animation stopped working once the buffer filled.** It animated on `levels.count`,
which stops changing the moment the rolling window is full — so the meter animated for its
first 120 samples and never again.

## ⚠️ Max-bucketed, not averaged

The load-bearing decision. Reducing thousands of samples to a few hundred bars by **averaging**
smears transients: a drum hit spread across its neighbours renders as a gentle swell, and the
file reads as softer than it is.

That is not cosmetic. Someone trimming to a beat aims at the peak, and an averaged waveform
moves the target.

Visible in the Component Lab: the same 4,000 peaks with three sharp transients, drawn at 460pt,
220pt and 90pt. At the narrowest each bar covers ~89 samples, and the hits are still there.

## A `Canvas`, not a stack of shapes

Both promoted copies built a `ForEach` of `Capsule` views — 120 for a live meter redrawing ten
times a second, and impossible for a track where a minute of audio carries thousands of peaks.
Keying that `ForEach` on the array index also gives every bar a new identity as the window
rolls, so SwiftUI animates each bar morphing into its neighbour rather than the strip scrolling.

## Inside a timeline

`AudioTrackWaveform` is sized by its container rather than by a time axis of its own, which is
exactly what lets it sit in `DesignScaffoldTimeline`'s `clipBody` while knowing nothing about
the timeline:

```swift
TimelineView(...) { clip in
    ZStack {
        clipTint
        AudioTrackWaveform(peaks: peaks(for: clip)).theme(.track)
    }
}
```

The timeline places and sizes the clip; the waveform fills what it is given; **the bucketing
re-runs at draw time against the width actually available**, so zooming keeps it honest.
Verified by zooming a clip through 30 · 60 · 120 pt/s with the transients intact at every scale.

## Edge behaviour worth knowing

- **Empty and silent are different.** No peaks draws the baseline alone; silent peaks draw
  minimum-height bars. A component that conflated them would make "not started" look like
  "no signal".
- **Fewer samples than bars are not stretched.** Three captured levels are three bars, not three
  smeared across two hundred — that would claim detail never measured.
- **An out-of-range `visible` slice draws nothing**, rather than clamping into the nearest part
  of the file. A waveform quietly showing the wrong audio is worse than one showing none.
- **Non-finite is silence, not maximum.** An infinity in a level buffer is a producer bug —
  usually a divide by zero in a dB conversion — and rendering it full-height would make a
  confident claim about the audio out of a broken number.
