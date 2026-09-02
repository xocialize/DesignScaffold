//
//  PlaylistActionButton.swift
//  DesignScaffoldPlaylist
//

import DesignScaffold
import SwiftUI

/// One trailing icon button, as ``PlaylistIterator`` draws it.
///
/// Public so that a host using the ``PlaylistIterator/rowAccessory(_:)`` escape hatch can
/// still compose the house button rather than redrawing it — and so the iOS Component Lab
/// can measure one on its own, since a band around the whole list cannot reach inside it.
public struct PlaylistActionButton: View {
    private let action: PlaylistRowAction
    var themeOverride: PlaylistTheme?

    var theme: PlaylistTheme { themeOverride ?? .scaffold }

    public init(_ action: PlaylistRowAction) { self.action = action }

    public var body: some View {
        Button(role: action.role == .destructive ? .destructive : nil) {
            action.handler()
        } label: {
            Image(systemName: action.resolvedSymbol)
                .font(theme.actionFont)
                .foregroundStyle(tint)
                // ⚠️ The drawn glyph area is `actionSize`; the HIT area is floored to the
                // platform minimum. On macOS that floor is zero, so this is the same 24pt
                // square it always was; on iOS it is 44, measured in the lab as the number
                // ChipRow failed at before it was floored the same way.
                .frame(minWidth: max(theme.actionSize, Tokens.Layout.minimumHitTarget),
                       minHeight: max(theme.actionSize, Tokens.Layout.minimumHitTarget))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(action.label)
        .accessibilityLabel(Text(action.label))
        .accessibilityAddTraits(action.isToggledOn ? [.isButton, .isSelected] : .isButton)
    }

    private var tint: Color {
        if action.role == .destructive { return theme.actionDestructiveTint }
        return action.isToggledOn ? theme.actionOnTint : theme.actionTint
    }
}

public extension PlaylistActionButton {
    /// Override the visual theme. Without this, ``PlaylistTheme/scaffold`` is used.
    func theme(_ theme: PlaylistTheme) -> PlaylistActionButton {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}
