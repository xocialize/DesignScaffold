//
//  MediaWellTheme.swift
//  DesignScaffoldMedia
//

import DesignScaffold
import SwiftUI

/// Visual styling for a ``MediaWell``. Initializer defaults are the token values.
///
/// PROVENANCE: the six copies agreed on the shape — a bordered region, an SF Symbol above a
/// one-line prompt, the content when there is any — and disagreed on height (150 / 180 / 260),
/// symbol, and whether the drop-targeted state was drawn at all. Half of them drew no
/// targeted state, so a drag over those wells gave no feedback until it was released.
public struct MediaWellTheme: Sendable {
    public var height: CGFloat
    public var cornerRadius: CGFloat
    public var fill: Color
    public var border: Color
    public var borderWidth: CGFloat
    /// The border while a drag is over the well. Deliberately the accent: "this will land here".
    public var targetedBorder: Color
    public var targetedBorderWidth: CGFloat
    public var targetedFill: Color
    public var symbolSize: CGFloat
    public var symbolColor: Color
    public var promptFont: Font
    public var promptColor: Color
    public var spacing: CGFloat

    public init(
        height: CGFloat = 180,
        cornerRadius: CGFloat = Tokens.Radius.container,
        fill: Color = Tokens.Color.fieldFill,
        border: Color = Tokens.Color.separator,
        borderWidth: CGFloat = Tokens.Layout.hairline,
        targetedBorder: Color = Tokens.Color.accent,
        targetedBorderWidth: CGFloat = 2,
        targetedFill: Color = Tokens.Color.selectionWash,
        symbolSize: CGFloat = 22,
        symbolColor: Color = Tokens.Color.tertiaryLabel,
        promptFont: Font = Tokens.Font.caption,
        promptColor: Color = Tokens.Color.secondaryLabel,
        spacing: CGFloat = Tokens.Space.s
    ) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.fill = fill
        self.border = border
        self.borderWidth = borderWidth
        self.targetedBorder = targetedBorder
        self.targetedBorderWidth = targetedBorderWidth
        self.targetedFill = targetedFill
        self.symbolSize = symbolSize
        self.symbolColor = symbolColor
        self.promptFont = promptFont
        self.promptColor = promptColor
        self.spacing = spacing
    }
}

public extension MediaWellTheme {
    /// The house style, and the default. 180pt — the median of the six.
    static let scaffold = MediaWellTheme()

    /// A tall well for a single hero input, as Trellis2's 260pt panel uses.
    static let tall = MediaWellTheme(height: 260)

    /// A short well for a secondary or optional input, as BiRefNet's 150pt thumbnail uses.
    static let compact = MediaWellTheme(height: 150, symbolSize: 18)
}
