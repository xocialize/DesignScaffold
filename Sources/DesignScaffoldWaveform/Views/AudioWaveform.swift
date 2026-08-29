//
//  AudioWaveform.swift
//  DesignScaffoldWaveform
//
//  The renderer. Both surfaces draw through this.
//

import DesignScaffold
import SwiftUI

/// Symmetric peak bars around a centre line.
///
/// ⚠️ **A `Canvas`, not a stack of shapes.** The two implementations this was promoted from
/// built a `ForEach` of `Capsule` views — 120 of them for a live meter, which is heavy for
/// something redrawing ten times a second, and impossible for a track visualiser where a
/// minute of audio can carry thousands of peaks. It also forced an identity problem: keying
/// `ForEach` on the array index means every bar changes identity each frame as the window
/// rolls, so SwiftUI animates each bar morphing into its neighbour instead of the strip
/// scrolling.
///
/// The bucketing happens at DRAW time against the width actually available, so the same peaks
/// render honestly at any size — which is what makes this usable inside a timeline clip that
/// changes width with zoom.
public struct AudioWaveform: View {

    private let peaks: [Float]
    private let isActive: Bool
    /// `.trailing` puts the newest sample at the right edge — the live-meter convention.
    private let alignment: HorizontalAlignment
    var themeOverride: WaveformTheme?

    var theme: WaveformTheme { themeOverride ?? .scaffold }

    public init(peaks: [Float], isActive: Bool = true,
                alignment: HorizontalAlignment = .center) {
        self.peaks = peaks
        self.isActive = isActive
        self.alignment = alignment
    }

    public var body: some View {
        Canvas { context, size in
            let midY = size.height / 2

            // ⚠️ Drawn even when there are no peaks. Silence and "not started" look identical
            // without it, and a meter showing nothing at all reads as broken rather than as
            // quiet — the reason both promoted copies carried this line.
            context.fill(
                Path(CGRect(x: 0, y: midY - Tokens.Layout.hairline / 2,
                            width: size.width, height: Tokens.Layout.hairline)),
                with: .color(theme.baseline))

            guard size.width > 0, size.height > 0 else { return }
            let bars = AudioPeaks.barCount(width: size.width,
                                           barWidth: theme.barWidth,
                                           spacing: theme.barSpacing)
            let values = AudioPeaks.bucket(peaks, into: bars)
            guard !values.isEmpty else { return }

            let pitch = theme.barWidth + theme.barSpacing
            // With fewer bars than fit, anchor them so the newest stays at the edge the caller
            // asked for. A live meter that grows from the left drifts away from the pointer.
            let used = CGFloat(values.count) * pitch - theme.barSpacing
            let originX: CGFloat
            switch alignment {
            case .trailing: originX = max(0, size.width - used)
            case .center:   originX = max(0, (size.width - used) / 2)
            default:        originX = 0
            }

            let color = isActive ? theme.active : theme.inactive
            for (i, value) in values.enumerated() {
                let height = max(theme.minimumBarHeight, CGFloat(value) * size.height)
                let rect = CGRect(x: originX + CGFloat(i) * pitch,
                                  y: midY - height / 2,
                                  width: theme.barWidth,
                                  height: height)
                context.fill(Path(roundedRect: rect, cornerRadius: theme.cornerRadius),
                             with: .color(color))
            }
        }
        .accessibilityHidden(true)
    }
}

public extension AudioWaveform {
    /// Override the visual theme. Without this, ``WaveformTheme/scaffold`` is used.
    func theme(_ theme: WaveformTheme) -> AudioWaveform {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}
