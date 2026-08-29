//
//  WaveformTheme.swift
//  DesignScaffoldWaveform
//

import DesignScaffold
import SwiftUI

/// Visual styling for the waveform views. Initializer defaults are the token values.
public struct WaveformTheme: Sendable {
    public var barWidth: CGFloat
    public var barSpacing: CGFloat
    /// The shortest a bar is drawn, so silence still registers as a signal at zero rather
    /// than as missing data.
    public var minimumBarHeight: CGFloat
    public var active: Color
    public var inactive: Color
    /// The centre line, drawn even with no peaks at all.
    public var baseline: Color
    public var cornerRadius: CGFloat

    public init(
        barWidth: CGFloat = 2,
        barSpacing: CGFloat = 1,
        minimumBarHeight: CGFloat = 2,
        active: Color = Tokens.Color.accent,
        inactive: Color = Tokens.Color.tertiaryLabel,
        baseline: Color = Tokens.Color.separator,
        cornerRadius: CGFloat = 1
    ) {
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.minimumBarHeight = minimumBarHeight
        self.active = active
        self.inactive = inactive
        self.baseline = baseline
        self.cornerRadius = cornerRadius
    }
}

public extension WaveformTheme {
    /// The house style, and the default.
    static let scaffold = WaveformTheme()

    /// Denser bars, for a waveform inside a timeline clip where width is scarce.
    static let track = WaveformTheme(barWidth: 1, barSpacing: 1, minimumBarHeight: 1)
}
