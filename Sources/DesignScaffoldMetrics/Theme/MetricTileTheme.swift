//
//  MetricTileTheme.swift
//  DesignScaffoldMetrics
//

import DesignScaffold
import SwiftUI

/// Visual styling for a ``MetricTile``. Initializer defaults are the token values.
public struct MetricTileTheme: Sendable {
    public var valueFont: Font
    public var unitFont: Font
    public var labelFont: Font
    public var captionFont: Font
    public var value: Color
    public var label: Color
    public var caption: Color
    public var spacing: CGFloat
    public var padding: CGFloat
    /// Below this the value shrinks rather than truncating — a clipped number is a wrong
    /// number, and a metric that shows "2.4…" has failed at its one job.
    public var minimumScale: CGFloat
    public var uppercasesLabel: Bool

    public init(
        valueFont: Font = Tokens.Font.metricValue,
        unitFont: Font = Tokens.Font.metricLabel,
        labelFont: Font = Tokens.Font.metricLabel,
        captionFont: Font = Tokens.Font.caption,
        value: Color = Tokens.Color.label,
        label: Color = Tokens.Color.secondaryLabel,
        caption: Color = Tokens.Color.tertiaryLabel,
        spacing: CGFloat = Tokens.Space.xs,
        padding: CGFloat = Tokens.Space.m,
        minimumScale: CGFloat = 0.6,
        uppercasesLabel: Bool = true
    ) {
        self.valueFont = valueFont
        self.unitFont = unitFont
        self.labelFont = labelFont
        self.captionFont = captionFont
        self.value = value
        self.label = label
        self.caption = caption
        self.spacing = spacing
        self.padding = padding
        self.minimumScale = minimumScale
        self.uppercasesLabel = uppercasesLabel
    }
}

public extension MetricTileTheme {
    /// The house style, and the default — a carded tile.
    static let scaffold = MetricTileTheme()

    /// No card, tighter type: for a metric sitting inside chrome that already has a surface,
    /// such as a sidebar's resident-memory block.
    static let inline = MetricTileTheme(valueFont: Tokens.Font.metricInline,
                                        padding: 0,
                                        uppercasesLabel: false)
}
