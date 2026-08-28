//
//  LabWindowController.swift
//  DesignWorkspace — Component Lab
//
//  Its own window, opened only for `-ComponentLab`, so the workspace app's normal startup
//  pipeline is untouched.
//

import AppKit
import SwiftUI

@MainActor
final class LabWindowController: NSWindowController {
    static var shared: LabWindowController?

    /// True when the process was launched to run the lab rather than the workspace app.
    static var requested: Bool {
        CommandLine.arguments.contains("-ComponentLab")
    }

    static func present() {
        if let existing = shared {
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "DesignScaffold — Component Lab"
        // `sizingOptions = []` — without it the hosting view pushes SwiftUI's ideal height up
        // into the window and it opens taller than the screen (measured: 2375pt for a window
        // asked for 760). A lab whose window size depends on which harness is selected also
        // moves every element between runs, which is the opposite of what this is for.
        let host = NSHostingView(rootView: ComponentLabView())
        host.sizingOptions = []
        window.contentView = host
        // Stable frame across relaunches: rebuild-launch-click cycles otherwise re-measure
        // every target for no reason.
        window.setFrameAutosaveName("ComponentLab")
        if window.frame.origin == .zero { window.center() }
        let controller = LabWindowController(window: window)
        shared = controller
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        LabLog.shared.note("LAB READY")
    }
}
