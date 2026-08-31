import DesignScaffold
import SwiftUI

/// Visual styling for a ``ChipRow``. Initializer defaults are the token values.
///
/// PROVENANCE: the `Main.dc.html` artboard agreed with ML[X] LTX Studio (AB-A-0032), whose
/// values are themselves token references — which is most of the argument for the component
/// existing: it reproduces the authority's own numbers rather than inventing any.
///
/// One divergence, recorded rather than applied silently: the artboard specifies **3pt
/// vertical / 9pt horizontal** padding. Both are a point off the 4pt grid, which reads as
/// drawn by eye for this element rather than derived. The defaults use `Space.xs` (4) and
/// `Space.s` (8); a caller who wants the artboard's exact figures sets them on the theme.
public struct ChipRowTheme: Sendable {

    public var selectedText: Color
    public var selectedFill: Color
    public var text: Color
    public var font: Font
    public var verticalPadding: CGFloat
    public var horizontalPadding: CGFloat
    /// Gap between chips, and between wrapped rows.
    public var spacing: CGFloat
    /// The floor for a chip's HIT area — not its drawn size. See
    /// ``Tokens/Layout/minimumHitTarget``: zero on macOS, so nothing moves; 44 on iOS,
    /// where the tap area grows around the capsule without resizing it.
    public var minimumHitTarget: CGFloat

    public init(
        selectedText: Color = Tokens.Color.accent,
        selectedFill: Color = Tokens.Color.selectionWash,
        text: Color = Tokens.Color.secondaryLabel,
        font: Font = Tokens.Font.caption,
        verticalPadding: CGFloat = Tokens.Space.xs,
        horizontalPadding: CGFloat = Tokens.Space.s,
        spacing: CGFloat = Tokens.Space.xs,
        minimumHitTarget: CGFloat = Tokens.Layout.minimumHitTarget
    ) {
        self.selectedText = selectedText
        self.selectedFill = selectedFill
        self.text = text
        self.font = font
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
        self.spacing = spacing
        self.minimumHitTarget = minimumHitTarget
    }
}

public extension ChipRowTheme {
    /// The house style, and the default.
    static var scaffold: ChipRowTheme { ChipRowTheme() }
}
