//
//  AudioSurfaces.swift
//  DesignScaffoldWaveform
//
//  The two shapes a waveform takes. Same renderer, different data contracts.
//

import DesignScaffold
import SwiftUI

/// A live input level meter — a rolling window of recent levels, newest at the right edge.
///
/// The host owns the window; ``AudioPeaks/rolling(_:appending:limit:)`` maintains it. That
/// split is the fix for what the promoted copies did: their view read the app's
/// `MicCapture.levelHistory` constant to compute a bar width, so the component could not be
/// used by an app whose buffer was a different size, and the buffer size silently controlled
/// the visual density.
///
/// ```swift
/// AudioLevelMeter(levels: capture.levels, isActive: capture.isRecording)
///     .frame(height: 32)
/// ```
public struct AudioLevelMeter: View {
    private let levels: [Float]
    private let isActive: Bool
    var themeOverride: WaveformTheme?

    public init(levels: [Float], isActive: Bool = true) {
        self.levels = levels
        self.isActive = isActive
    }

    public var body: some View {
        AudioWaveform(peaks: levels, isActive: isActive, alignment: .trailing)
            .theme(themeOverride ?? .scaffold)
            .accessibilityElement()
            .accessibilityLabel(isActive ? "Audio input level" : "Audio input idle")
    }
}

public extension AudioLevelMeter {
    func theme(_ theme: WaveformTheme) -> AudioLevelMeter {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}

/// A whole asset's waveform, drawn to fill its frame — for a timeline clip body, or any
/// fixed-extent audio view.
///
/// Sized by its container rather than by a time axis of its own, which is what lets it sit
/// inside `DesignScaffoldTimeline`'s `clipBody` without knowing anything about the timeline:
/// the component places and sizes the clip, and this fills what it is given. Zooming changes
/// the width, the bucketing re-runs against it, and the waveform stays honest at every scale.
///
/// ```swift
/// TimelineView(...) { clip in
///     AudioTrackWaveform(peaks: peaks(for: clip))
///         .theme(.track)
/// }
/// ```
///
/// Pass `visible` to draw only part of the asset — a clip that references a slice of a longer
/// file:
///
/// ```swift
/// AudioTrackWaveform(peaks: assetPeaks, duration: assetSeconds, visible: clip.sourceRange)
/// ```
public struct AudioTrackWaveform: View {
    private let peaks: [Float]
    private let isActive: Bool
    var themeOverride: WaveformTheme?

    /// The whole asset.
    public init(peaks: [Float], isActive: Bool = true) {
        self.peaks = peaks
        self.isActive = isActive
    }

    /// A time slice of the asset.
    ///
    /// An out-of-range window draws nothing rather than clamping into the wrong part of the
    /// file — a waveform that quietly shows the wrong audio is worse than one that shows none.
    public init(peaks: [Float], duration: TimeInterval,
                visible: ClosedRange<TimeInterval>, isActive: Bool = true) {
        self.peaks = AudioPeaks.slice(peaks, duration: duration, range: visible)
        self.isActive = isActive
    }

    public var body: some View {
        AudioWaveform(peaks: peaks, isActive: isActive, alignment: .center)
            .theme(themeOverride ?? .track)
            .accessibilityElement()
            .accessibilityLabel("Audio waveform")
    }
}

public extension AudioTrackWaveform {
    func theme(_ theme: WaveformTheme) -> AudioTrackWaveform {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}
