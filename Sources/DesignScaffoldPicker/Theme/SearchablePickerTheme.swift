//
//  SearchablePickerTheme.swift
//  DesignScaffoldPicker
//

import DesignScaffold
import SwiftUI

/// Visual styling for a ``SearchablePicker``. Initializer defaults are the token values.
public struct SearchablePickerTheme: Sendable {
    public var rowFill: Color
    public var rowSelectedFill: Color
    public var fieldFill: Color
    public var border: Color
    public var accent: Color
    public var nameText: Color
    public var secondaryText: Color
    public var mutedText: Color
    public var nameFont: Font
    public var captionFont: Font
    public var countFont: Font
    public var actionFont: Font
    public var cornerRadius: CGFloat
    public var rowSpacing: CGFloat

    public init(
        rowFill: Color = Tokens.Color.fieldFill,
        rowSelectedFill: Color = Tokens.Color.selectionWash,
        fieldFill: Color = Tokens.Color.fieldFill,
        border: Color = Tokens.Color.separator,
        accent: Color = Tokens.Color.accent,
        nameText: Color = Tokens.Color.label,
        secondaryText: Color = Tokens.Color.secondaryLabel,
        mutedText: Color = Tokens.Color.tertiaryLabel,
        nameFont: Font = Tokens.Font.body,
        captionFont: Font = Tokens.Font.caption,
        countFont: Font = Tokens.Font.metricLabel,
        actionFont: Font = Tokens.Font.sectionTitle,
        cornerRadius: CGFloat = Tokens.Radius.control,
        rowSpacing: CGFloat = 3
    ) {
        self.rowFill = rowFill
        self.rowSelectedFill = rowSelectedFill
        self.fieldFill = fieldFill
        self.border = border
        self.accent = accent
        self.nameText = nameText
        self.secondaryText = secondaryText
        self.mutedText = mutedText
        self.nameFont = nameFont
        self.captionFont = captionFont
        self.countFont = countFont
        self.actionFont = actionFont
        self.cornerRadius = cornerRadius
        self.rowSpacing = rowSpacing
    }
}

public extension SearchablePickerTheme {
    /// The house style, and the default.
    static let scaffold = SearchablePickerTheme()
}
