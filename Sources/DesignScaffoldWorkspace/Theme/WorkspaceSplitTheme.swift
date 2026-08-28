//
//  WorkspaceSplitTheme.swift
//  DesignScaffoldWorkspace
//

import DesignScaffold
import SwiftUI

/// Visual styling for a ``WorkspaceSplit``. Initializer defaults are the token values.
///
/// PROVENANCE: measured from four independent shells rather than designed — MarqueeStudio's
/// Screen manager (350 · 300) and playlist Editor (420 · 360), ML[X] Media Forge's Optimizer
/// (300 · 300 around an 800pt minimum), and DesignWorkspace (260, two-pane). The defaults are
/// the existing `Tokens.Layout` values; every app above is free to keep its own numbers, and
/// the point of the type is that it stops re-deriving the STRUCTURE.
public struct WorkspaceSplitTheme: Sendable {

    /// Width of the leading navigation pane.
    public var leadingWidth: CGFloat
    /// Width of the trailing inspector pane.
    public var trailingWidth: CGFloat
    /// The narrowest the center work area may become before the side panes yield.
    public var centerMinimum: CGFloat
    /// Fill behind the side panes.
    public var paneFill: Color
    /// Fill behind the center.
    ///
    /// ⚠️ Defaults to `.clear`, which is load-bearing rather than lazy: ML[X] Media Forge
    /// mounts an `NSVisualEffectView` behind this layout and needs the center transparent so
    /// the window's vibrancy shows through. A center painted with a surface colour by default
    /// would silently flatten that, and the app would have no way to ask for it back short of
    /// not using the component.
    public var centerFill: Color
    /// Hairlines between the panes. Set `false` for a shell that draws its own edges.
    public var showsSeparators: Bool

    public init(
        leadingWidth: CGFloat = Tokens.Layout.sidebarWidth,
        trailingWidth: CGFloat = Tokens.Layout.inspectorWidth,
        centerMinimum: CGFloat = 320,
        paneFill: Color = Tokens.Color.surface,
        centerFill: Color = .clear,
        showsSeparators: Bool = true
    ) {
        self.leadingWidth = leadingWidth
        self.trailingWidth = trailingWidth
        self.centerMinimum = centerMinimum
        self.paneFill = paneFill
        self.centerFill = centerFill
        self.showsSeparators = showsSeparators
    }
}

public extension WorkspaceSplitTheme {
    /// The house style, and the default.
    static let scaffold = WorkspaceSplitTheme()
}
