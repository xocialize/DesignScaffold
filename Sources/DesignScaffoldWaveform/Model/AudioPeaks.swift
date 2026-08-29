//
//  AudioPeaks.swift
//  DesignScaffoldWaveform
//
//  The arithmetic behind a waveform, kept pure so the part that decides what the user SEES of
//  their audio is testable without a view.
//

import CoreGraphics
import Foundation

public enum AudioPeaks {

    /// Reduce `samples` to exactly `bars` values by taking the LOUDEST in each bucket.
    ///
    /// ⚠️ **Max, not mean.** Averaging smears transients: a drum hit spread across its
    /// neighbours renders as a gentle swell, and the waveform reads as quieter, softer content
    /// than the file actually contains. That is not a cosmetic difference — someone trimming to
    /// a beat is aiming at the peak, and an averaged waveform moves the target.
    ///
    /// Returns an empty array when there is nothing to draw, rather than a row of zeros: an
    /// empty waveform and a silent one are different states, and the renderer distinguishes
    /// them (silence still draws a baseline, so it reads as "listening" rather than "broken").
    public static func bucket(_ samples: [Float], into bars: Int) -> [Float] {
        guard bars > 0, !samples.isEmpty else { return [] }
        guard samples.count > bars else {
            // Fewer samples than bars: nothing to reduce. Do NOT stretch them across the width
            // — a host that has captured 3 levels should see 3 bars, not 3 bars smeared into
            // 200, which would claim detail that was never measured.
            return samples.map(clamp)
        }
        var out = [Float](repeating: 0, count: bars)
        let stride = Double(samples.count) / Double(bars)
        for bar in 0..<bars {
            let lower = Int(Double(bar) * stride)
            let upper = min(samples.count, max(lower + 1, Int(Double(bar + 1) * stride)))
            var peak: Float = 0
            for i in lower..<upper { peak = max(peak, abs(samples[i])) }
            out[bar] = clamp(peak)
        }
        return out
    }

    /// How many bars fit in `width` at this bar pitch. Never negative, never absurd.
    public static func barCount(width: CGFloat, barWidth: CGFloat, spacing: CGFloat) -> Int {
        let pitch = max(0.5, barWidth + spacing)
        guard width > 0 else { return 0 }
        return max(1, Int(width / pitch))
    }

    /// Append a level to a rolling window, dropping the oldest to stay within `limit`.
    ///
    /// The live-meter idiom, lifted from the two apps this was promoted from — where it lived
    /// in each app's audio capture class, so the VIEW had to import the app's buffer size to
    /// know how wide a bar should be. It belongs with the data.
    public static func rolling(_ window: [Float], appending level: Float, limit: Int) -> [Float] {
        guard limit > 0 else { return [] }
        var next = window
        next.append(clamp(level))
        if next.count > limit { next.removeFirst(next.count - limit) }
        return next
    }

    /// The slice of a full-duration peak set covering `range` seconds of `duration`.
    ///
    /// For a track visualiser: the host holds peaks for the whole asset and draws only the part
    /// a clip exposes. An out-of-range request yields an empty slice rather than a clamped one,
    /// because silently drawing the wrong part of a file is worse than drawing nothing.
    public static func slice(_ peaks: [Float], duration: TimeInterval,
                             range: ClosedRange<TimeInterval>) -> [Float] {
        guard !peaks.isEmpty, duration > 0, range.lowerBound < duration, range.upperBound > 0
        else { return [] }
        let perSecond = Double(peaks.count) / duration
        let lower = max(0, Int((range.lowerBound * perSecond).rounded(.down)))
        let upper = min(peaks.count, Int((range.upperBound * perSecond).rounded(.up)))
        guard lower < upper else { return [] }
        return Array(peaks[lower..<upper])
    }

    private static func clamp(_ v: Float) -> Float { min(1, max(0, v.isFinite ? abs(v) : 0)) }
}
