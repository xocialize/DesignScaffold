//
//  MainLayoutView.swift
//  DesignWorkspace
//
//  The app's top-level UI layer: a fixed three-panel layout.
//

import SwiftUI
import DesignScaffold

/// The app's top-level UI layer.
///
/// Three columns sit side by side:
///   - a 300pt left panel,
///   - an 800pt center region left intentionally empty, and
///   - a 300pt right panel.
///
/// The left and right panels are filled with the design-system surface color
/// (`Tokens.Color.surface`). The center is `Color.clear` so the window's
/// vibrancy material — an `NSVisualEffectView` mounted behind this view in
/// `MainWindowController` — shows through.
struct MainLayoutView: View {

    /// Fixed width of the left and right panels.
    static let panelWidth: CGFloat = 300
    /// Width of the empty center region.
    static let centerWidth: CGFloat = 800
    /// The layout's natural width: two panels plus the center.
    static let contentWidth: CGFloat = panelWidth * 2 + centerWidth
    /// The window's initial content height.
    static let contentHeight: CGFloat = 1080

    var body: some View {
        HStack(spacing: 0) {
            SidePanel()
                .frame(width: Self.panelWidth)

            // Center: the Metal display preview. Flexible so it absorbs all extra
            // window width — that keeps the fixed-width panels pinned to the left
            // and right edges instead of the whole row centering. Starts at
            // `centerWidth` (800) and never drops below it. The region stays clear
            // so the window's vibrancy shows through around the square.
            MetalPreviewView()
                .frame(minWidth: Self.centerWidth, maxWidth: .infinity)

            SidePanel()
                .frame(width: Self.panelWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A single side column, filled with the shared design-system surface color so
/// both panels stay in step with the rest of the fleet's apps. A hairline
/// separator marks its edge against the vibrant center.
private struct SidePanel: View {
    var body: some View {
        Tokens.Color.surface
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainLayoutView()
        .frame(width: MainLayoutView.contentWidth, height: MainLayoutView.contentHeight)
}
