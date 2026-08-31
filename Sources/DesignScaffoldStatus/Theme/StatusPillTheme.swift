//
//  StatusPillTheme.swift
//  DesignScaffoldStatus
//

import DesignScaffold
import SwiftUI

/// Visual styling for a ``StatusPill``. Initializer defaults are the token values.
///
/// PROVENANCE: the eight copies agreed on nearly everything — a 6pt dot, ~6pt gap, caption
/// text, 4pt vertical padding, a capsule on an elevated fill. Where they disagreed the
/// majority won, except on colour, which comes from the status tokens rather than from any
/// one app's palette.
public struct StatusPillTheme: Sendable {
    public var dotSize: CGFloat
    public var spacing: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat
    public var fill: Color
    public var text: Color
    public var font: Font
    public var idle: Color
    public var working: Color
    public var ready: Color
    public var degraded: Color
    public var failed: Color
    /// One breath. Shared with ``StageStepper`` via `Tokens.Motion`.
    public var pulseDuration: Double
    public var pulseMinOpacity: Double
    /// The steady opacity the dot holds under Reduce Motion.
    public var reducedMotionOpacity: Double

    public init(
        dotSize: CGFloat = 6,
        spacing: CGFloat = Tokens.Space.xs + 2,
        horizontalPadding: CGFloat = Tokens.Space.s + 2,
        verticalPadding: CGFloat = Tokens.Space.xs,
        fill: Color = Tokens.Color.fillElevated,
        text: Color = Tokens.Color.secondaryLabel,
        font: Font = Tokens.Font.caption,
        idle: Color = Tokens.Color.tertiaryLabel,
        working: Color = Tokens.Color.working,
        ready: Color = Tokens.Color.ready,
        degraded: Color = Tokens.Color.degraded,
        failed: Color = Tokens.Color.failure,
        pulseDuration: Double = Tokens.Motion.pulseDuration,
        pulseMinOpacity: Double = Tokens.Motion.pulseMinOpacity,
        reducedMotionOpacity: Double = Tokens.Motion.reducedMotionOpacity
    ) {
        self.dotSize = dotSize
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.fill = fill
        self.text = text
        self.font = font
        self.idle = idle
        self.working = working
        self.ready = ready
        self.degraded = degraded
        self.failed = failed
        self.pulseDuration = pulseDuration
        self.pulseMinOpacity = pulseMinOpacity
        self.reducedMotionOpacity = reducedMotionOpacity
    }

    /// The dot colour for a status.
    public func color(for status: Status) -> Color {
        switch status {
        case .idle:    return idle
        case .working: return working
        case .ready:    return ready
        case .degraded: return degraded
        case .failed:  return failed
        }
    }
}

public extension StatusPillTheme {
    /// The house style, and the default.
    static let scaffold = StatusPillTheme()
}
