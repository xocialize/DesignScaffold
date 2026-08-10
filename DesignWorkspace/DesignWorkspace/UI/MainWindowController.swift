//
//  MainWindowController.swift
//  DesignWorkspace
//
//  Builds the main window programmatically (no IB) and wires the vibrancy
//  background beneath the SwiftUI UI layer.
//

import Cocoa
import SwiftUI

/// Owns the app's main window.
///
/// The window's content view is an `NSVisualEffectView`, so the window
/// background is vibrant (it samples the desktop/wallpaper behind it). The
/// SwiftUI UI layer (`MainLayoutView`) is hosted on top with a transparent
/// background, so the vibrancy shows through the empty center column while the
/// side panels paint their own surface fill over it.
@MainActor
final class MainWindowController: NSWindowController {

    /// Initial content size: 300 (left) + 800 (center) + 300 (right) = 1400 wide,
    /// 1080 tall, matching `MainLayoutView`'s natural dimensions.
    static let initialContentSize = NSSize(
        width: MainLayoutView.contentWidth,
        height: MainLayoutView.contentHeight
    )

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.initialContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DesignWorkspace"
        window.isReleasedWhenClosed = false
        // Floor: two 300pt panels plus the 800pt center. Keeps the panels from
        // being crushed and the center from dropping below its intended width.
        window.contentMinSize = NSSize(width: MainLayoutView.contentWidth, height: 500)
        window.center()

        // Window-level vibrancy. `.behindWindow` blending samples what's behind
        // the window; `.underWindowBackground` is the material intended for a
        // window's base background.
        let vibrancy = NSVisualEffectView()
        vibrancy.material = .underWindowBackground
        vibrancy.blendingMode = .behindWindow
        vibrancy.state = .active
        window.contentView = vibrancy

        // The SwiftUI UI layer, pinned to fill the vibrancy view. NSHostingView
        // is transparent by default, so the vibrancy shows through Color.clear.
        let hosting = NSHostingView(rootView: MainLayoutView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        vibrancy.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: vibrancy.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: vibrancy.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: vibrancy.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: vibrancy.bottomAnchor),
        ])

        self.init(window: window)
    }

    /// Bring the window on screen and make it key.
    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
