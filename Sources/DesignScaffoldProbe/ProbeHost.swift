//
//  ⚠️ macOS-only. This target is wrapped in `#if os(macOS)` because it is built on AppKit
//  API with no iOS equivalent — see `Docs/PLATFORMS.md`. On iOS the module compiles to
//  nothing, so an app that adds this product by mistake gets "cannot find X in scope"
//  rather than a wall of AppKit errors, and the package as a whole still builds.
//
#if os(macOS)

//
//  ProbeHost.swift
//  DesignScaffoldProbe
//
//  The one accessibility element a driver talks to: read its value for the channel's snapshot,
//  set its value to run a command.
//

import AppKit
import SwiftUI

/// The probe host: an invisible 1 × 1 view whose accessibility identifier is
/// `DesignScaffoldProbe`. Reading its AX value returns `ProbeChannel`'s JSON snapshot; writing a
/// JSON command to it runs the command on the main thread, and the next read carries the reply.
///
/// It's inert, and absent from the accessibility tree, unless the probe is enabled
/// (`DESIGNSCAFFOLD_PROBE=1`), so it costs a shipping app nothing.
final class ProbeHostView: NSView {
    static let identifier = "DesignScaffoldProbe"

    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityIdentifier(Self.identifier)
        MainActor.assumeIsolated { ProbeChannel.startIfNeeded() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func isAccessibilityElement() -> Bool { MainActor.assumeIsolated { HitTestProbe.isEnabled } }
    override func accessibilityRole() -> NSAccessibility.Role? { .textArea }
    override func accessibilityLabel() -> String? { "DesignScaffold probe" }

    override func accessibilityValue() -> Any? {
        let json: String? = MainActor.assumeIsolated { HitTestProbe.isEnabled ? ProbeChannel.serialized() : nil }
        return json
    }

    override func setAccessibilityValue(_ value: Any?) {
        guard let text = value as? String else { return }
        MainActor.assumeIsolated {
            guard HitTestProbe.isEnabled else { return }
            ProbeChannel.run(text)
        }
    }

    /// Lets AX clients set the value (AXUIElementIsAttributeSettable reads this).
    override func isAccessibilitySelectorAllowed(_ selector: Selector) -> Bool {
        if selector == #selector(setAccessibilityValue(_:)) { return true }
        return super.isAccessibilitySelectorAllowed(selector)
    }

    // A probe that took a click would be a hit-testing bug inside the hit-testing instrument.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

private struct ProbeHostRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> ProbeHostView { ProbeHostView(frame: NSRect(x: 0, y: 0, width: 1, height: 1)) }
    func updateNSView(_ nsView: ProbeHostView, context: Context) {}
}

public extension View {
    /// Mounts the probe host, which a driver (AppProbe) reads and commands over accessibility.
    /// Put it once on a window's root view. Inert unless the probe is enabled.
    func designScaffoldProbeHost() -> some View {
        background(alignment: .topLeading) {
            if HitTestProbe.isEnabled {
                ProbeHostRepresentable()
                    .frame(width: 1, height: 1)
                    .allowsHitTesting(false)
            }
        }
    }
}

@MainActor
public extension HitTestProbe {
    /// Mounts the probe host in an AppKit window, for a window whose content isn't SwiftUI.
    static func installHost(in window: NSWindow) {
        guard isEnabled, let content = window.contentView,
              !content.subviews.contains(where: { $0 is ProbeHostView }) else { return }
        content.addSubview(ProbeHostView(frame: NSRect(x: 0, y: 0, width: 1, height: 1)))
    }
}

// MARK: - Input to AppKit views, without the pointer

/// Mouse input sent straight to an AppKit view: `mouseDown`, `mouseDragged` and `mouseUp` with
/// real `NSEvent`s, as the app's own hosted tests do. No pointer moves and the app needn't be in
/// front, so a driver can paint, select and drag on a canvas while the operator keeps working.
///
/// ⚠️ This tests what the VIEW does with a press, not whether the press would reach it: window
/// hit testing, a sheet in the way, and first-click activation are all skipped. Those are the
/// real pointer's job (`Tools/InputDriver`, AppProbe's `pointer`). And it reaches AppKit views
/// only: a SwiftUI gesture ignores events it didn't get through the window (measured in
/// DesignWorkspace: `NSApp.sendEvent` and direct `mouseDown` were inert there).
@MainActor
public enum ProbeInput {
    /// Points are in the view's own coordinates (`view.bounds`, flipped or not as the view is).
    public static func click(_ view: NSView, at point: CGPoint, count: Int = 1,
                             modifiers: NSEvent.ModifierFlags = []) throws {
        for n in 1...max(count, 1) {
            try send(.leftMouseDown, to: view, at: point, clickCount: n, modifiers: modifiers)
            try send(.leftMouseUp, to: view, at: point, clickCount: n, modifiers: modifiers)
        }
    }

    /// A press at the first point, drags through the rest, a release at the last.
    public static func drag(_ view: NSView, along points: [CGPoint], modifiers: NSEvent.ModifierFlags = []) throws {
        guard let first = points.first, let last = points.last else { throw ProbeError("a drag needs at least one point") }
        try send(.leftMouseDown, to: view, at: first, modifiers: modifiers)
        for p in points.dropFirst() { try send(.leftMouseDragged, to: view, at: p, modifiers: modifiers) }
        try send(.leftMouseUp, to: view, at: last, modifiers: modifiers)
    }

    /// A straight drag in `steps` moves.
    public static func drag(_ view: NSView, from a: CGPoint, to b: CGPoint, steps: Int = 12,
                            modifiers: NSEvent.ModifierFlags = []) throws {
        let n = max(steps, 1)
        let points = (0...n).map { i -> CGPoint in
            let t = CGFloat(i) / CGFloat(n)
            return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        try drag(view, along: points, modifiers: modifiers)
    }

    static func send(_ type: NSEvent.EventType, to view: NSView, at point: CGPoint, clickCount: Int = 1,
                     modifiers: NSEvent.ModifierFlags) throws {
        guard let window = view.window else { throw ProbeError("the view isn't in a window") }
        let location = view.convert(point, to: nil)
        guard let event = NSEvent.mouseEvent(with: type, location: location, modifierFlags: modifiers,
                                             timestamp: ProcessInfo.processInfo.systemUptime,
                                             windowNumber: window.windowNumber, context: nil, eventNumber: 0,
                                             clickCount: clickCount, pressure: type == .leftMouseUp ? 0 : 1) else {
            throw ProbeError("couldn't make a \(type) event")
        }
        switch type {
        case .leftMouseDown: view.mouseDown(with: event)
        case .leftMouseDragged: view.mouseDragged(with: event)
        case .leftMouseUp: view.mouseUp(with: event)
        default: throw ProbeError("unsupported event \(type)")
        }
    }
}

#endif
