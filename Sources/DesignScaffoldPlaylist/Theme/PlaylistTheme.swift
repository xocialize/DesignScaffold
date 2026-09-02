import DesignScaffold
import SwiftUI

/// Visual styling for a ``PlaylistIterator``.
///
/// The default theme is ``scaffold`` — every colour, metric, and font resolved through
/// `Tokens`. The initialiser's defaults are the token values, so a custom theme that
/// only overrides colours still inherits the scaffold geometry.
///
/// PROVENANCE: generalised from MarqueeStudio's playlist rail (`PlaylistEditorView`).
/// Where the studio's ad-hoc values disagreed with the tokens, the token won:
///
///     thumbnail     44 → Tokens.Layout.rowHeight (42)   the kit's form-row height
///     row radius    6  = Tokens.Radius.control (6)      already the kit value
///     name font     13 medium → Tokens.Font.body.weight(.medium)
///     meta label    10 semibold → Tokens.Font.metricLabel (10 medium)
///     meta value    10 mono → Tokens.Font.mono (11 monospaced)
///     selection     accent@0.18 → accent@0.15           the calendar's in-range wash
///     row dividers  bgElevated → Tokens.Color.separator
public struct PlaylistTheme: Sendable {

    // Colours
    /// Fill behind a selected row.
    public var selectionWash: Color
    /// Border ring marking the ACTIVE (current / now-playing) row — distinct from selection.
    public var activeRing: Color
    public var nameText: Color
    /// Index numbers, the drag handle, and metadata labels.
    public var secondaryText: Color
    public var metadataValueText: Color
    /// Fill behind a thumbnail (visible until the caller's thumbnail covers it).
    public var thumbnailFill: Color
    /// The placeholder symbol shown when no thumbnail content is supplied.
    public var thumbnailPlaceholder: Color
    /// Hairline between rows.
    public var separator: Color
    public var emptyText: Color
    /// Name and metadata of a row whose ``PlaylistRowState`` is not `.normal`.
    public var dimmedText: Color

    // Trailing action column — see ``PlaylistRowAction``.
    public var actionTint: Color
    /// A toggle that is ON. Amber, which is what ML[X] Audio Studio's favourite star chose
    /// before the column existed — promoted, not invented.
    public var actionOnTint: Color
    public var actionDestructiveTint: Color
    /// The drawn glyph area. The HIT area is this floored to `Tokens.Layout.minimumHitTarget`.
    public var actionSize: CGFloat
    public var actionSpacing: CGFloat
    public var actionFont: Font

    // Metrics
    /// Thumbnail square edge.
    public var thumbnailSize: CGFloat
    /// Radius of the thumbnail, the active ring, and the selection wash.
    public var cornerRadius: CGFloat
    public var rowHorizontalPadding: CGFloat
    public var rowVerticalPadding: CGFloat
    /// Horizontal gap between the row's elements.
    public var contentSpacing: CGFloat
    public var activeRingWidth: CGFloat

    // Fonts
    public var nameFont: Font
    public var indexFont: Font
    public var metadataLabelFont: Font
    public var metadataValueFont: Font
    public var emptyFont: Font

    public init(
        selectionWash: Color = Tokens.Color.selectionWash,
        activeRing: Color = Tokens.Color.accent,
        nameText: Color = Tokens.Color.label,
        secondaryText: Color = Tokens.Color.secondaryLabel,
        metadataValueText: Color = Tokens.Color.secondaryLabel,
        thumbnailFill: Color = Tokens.Color.surfaceElevated,
        thumbnailPlaceholder: Color = Tokens.Color.tertiaryLabel,
        separator: Color = Tokens.Color.separator,
        emptyText: Color = Tokens.Color.tertiaryLabel,
        thumbnailSize: CGFloat = Tokens.Layout.rowHeight,
        cornerRadius: CGFloat = Tokens.Radius.control,
        rowHorizontalPadding: CGFloat = Tokens.Space.m,
        rowVerticalPadding: CGFloat = Tokens.Space.s,
        contentSpacing: CGFloat = Tokens.Space.s,
        activeRingWidth: CGFloat = 1.5,
        nameFont: Font = Tokens.Font.body.weight(.medium),
        indexFont: Font = Tokens.Font.caption,
        metadataLabelFont: Font = Tokens.Font.metricLabel,
        metadataValueFont: Font = Tokens.Font.mono,
        emptyFont: Font = Tokens.Font.caption,
        dimmedText: Color = Tokens.Color.tertiaryLabel,
        actionTint: Color = Tokens.Color.secondaryLabel,
        actionOnTint: Color = Tokens.Color.working,
        actionDestructiveTint: Color = Tokens.Color.failure,
        actionSize: CGFloat = Tokens.Layout.controlHeight,
        actionSpacing: CGFloat = Tokens.Space.xs,
        actionFont: Font = Tokens.Font.body
    ) {
        self.selectionWash = selectionWash
        self.activeRing = activeRing
        self.nameText = nameText
        self.secondaryText = secondaryText
        self.metadataValueText = metadataValueText
        self.thumbnailFill = thumbnailFill
        self.thumbnailPlaceholder = thumbnailPlaceholder
        self.separator = separator
        self.emptyText = emptyText
        self.thumbnailSize = thumbnailSize
        self.cornerRadius = cornerRadius
        self.rowHorizontalPadding = rowHorizontalPadding
        self.rowVerticalPadding = rowVerticalPadding
        self.contentSpacing = contentSpacing
        self.activeRingWidth = activeRingWidth
        self.nameFont = nameFont
        self.indexFont = indexFont
        self.metadataLabelFont = metadataLabelFont
        self.metadataValueFont = metadataValueFont
        self.emptyFont = emptyFont
        self.dimmedText = dimmedText
        self.actionTint = actionTint
        self.actionOnTint = actionOnTint
        self.actionDestructiveTint = actionDestructiveTint
        self.actionSize = actionSize
        self.actionSpacing = actionSpacing
        self.actionFont = actionFont
    }
}

public extension PlaylistTheme {
    /// The house style, and the default — every slot resolved through `Tokens`.
    static var scaffold: PlaylistTheme { PlaylistTheme() }
}
