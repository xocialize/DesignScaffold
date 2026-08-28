//
//  HitTestProbe.swift
//  DesignScaffoldProbe
//
//  The pointer gate: report where a view was DRAWN, and what a gesture actually DID.
//

import AppKit
import SwiftUI

/// Reports each target's click point in the coordinate space `CGEvent` uses, and the outcomes
/// a harness needs to assert on.
///
/// ## Why this is a product
///
/// Every defect this library has shipped after compiling was found by a pointer, and none by a
/// headless test. Renders prove placement; unit tests prove arithmetic; neither can reach hit
/// testing or gesture lifetime. Two apps had independently written this — ML[X] LTX Studio's
/// `HitTestProbe` and DesignWorkspace's `DrawnFrameProbe` — and each had learned something the
/// other had not. This is the union, so the next app gets both.
///
/// ⚠️ **Take the click target from the DRAWING, never from geometry you compute.** The bug class
/// is "what is drawn and what is hit disagree", so a probe that computed its own rect would
/// agree with the bug. This is why `record` takes a frame reported by a `GeometryReader` rather
/// than deriving one.
///
/// ## Opt-in, and inert until asked
///
/// A separate product, so an app links it deliberately, and every entry point returns
/// immediately unless enabled. Enable with the launch argument `-DesignScaffoldProbe YES`, or
/// by setting `DESIGNSCAFFOLD_PROBE` in the environment.
///
/// ```swift
/// SomeClip(clip)
///     .hitTestProbe("clip-\(clip.id)")
/// ```
///
/// Then drive it with `Tools/InputDriver` at the reported coordinates. `Tools/README.md`
/// carries the four rules that make synthetic input register.
@MainActor
public enum HitTestProbe {

    // MARK: Enablement

    public static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "DesignScaffoldProbe")
            || ProcessInfo.processInfo.environment["DESIGNSCAFFOLD_PROBE"] != nil
    }

    /// Where lines go. Defaults to stdout, which is what a shell harness reads.
    ///
    /// An app with its own logging replaces this — ML[X] LTX Studio routes its probe through
    /// `OSLog`, and losing that would have been a reason not to adopt.
    public static var emit: (String) -> Void = { line in
        print(line)
        fflush(stdout)
    }

    // MARK: Targets

    private struct Target {
        let name: String
        let rect: CGRect      // SwiftUI `.global` space
    }

    private static var targets: [String: Target] = [:]
    private static var flushTask: Task<Void, Never>?

    /// Register a rendered target and its drawn frame in SwiftUI's `.global` space.
    ///
    /// ⚠️ **No non-zero guard.** An earlier version skipped empty frames, which made the probe
    /// lie in the one case worth seeing: a pane that collapses to zero never reported again, so
    /// the probe kept serving its last non-zero size and a correctly-collapsed pane read as one
    /// that had ignored its frame. A zero is a measurement.
    public static func record(name: String, frame: CGRect) {
        guard isEnabled else { return }
        targets[name] = Target(name: name, rect: frame)
        // Coalesce: SwiftUI reports geometry repeatedly during layout, and one settled report is
        // worth more than fifty in flight. Re-reporting on every change also goes STALE the
        // moment an edit resizes something, so the flush always prints the whole current set
        // rather than a running commentary.
        flushTask?.cancel()
        flushTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            flush()
        }
    }

    /// Print every target's centre in the space `CGEvent` uses: origin at the TOP-LEFT of the
    /// primary display, y increasing downward.
    public static func flush() {
        guard isEnabled else { return }
        guard let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }),
              let primary = NSScreen.screens.first else {
            emit("PROBE ERROR no visible window to convert against")
            return
        }
        // ⚠️ SwiftUI's `.global` space is the window FRAME, not the content view — measured in
        // two apps independently, and both got it wrong first. Routing through
        // `contentView.bounds` puts every target exactly one title bar (~27-34pt) too low, and
        // a target computed by hand landed 27pt off for the same reason.
        let frame = window.frame                              // AppKit screen space, y up
        let windowTop = primary.frame.height - frame.maxY     // CGEvent space, y down

        for target in targets.values.sorted(by: { $0.rect.minX < $1.rect.minX }) {
            let r = target.rect
            emit(String(format: "PROBE TARGET %@ centre %d %d size %dx%d",
                        target.name,
                        Int((frame.minX + r.midX).rounded()),
                        Int((windowTop + r.midY).rounded()),
                        Int(r.width), Int(r.height)))
        }
        emit("PROBE READY \(targets.count)")
    }

    public static func reset() { targets.removeAll() }

    // MARK: Outcomes
    //
    // Coordinates alone cannot close a gate. "The click landed" and "the right thing happened"
    // are different questions, and the second is the one that catches a gesture which previews
    // correctly and commits nothing.

    /// What the app believes is selected, in terms a harness can assert on.
    public static func selection(_ names: [String]) {
        guard isEnabled else { return }
        emit("PROBE SELECTION \(names.isEmpty ? "none" : names.sorted().joined(separator: ","))")
    }

    /// A target that ACTS rather than selects — a button drawn inside a decoration.
    ///
    /// ⚠️ A decoration with a click target is not a decoration. That category looked green
    /// twice while being broken under a pointer.
    public static func activation(_ name: String) {
        guard isEnabled else { return }
        emit("PROBE ACTIVATION \(name)")
    }

    /// A context-menu ITEM fired, and on what.
    ///
    /// ⚠️ From outside the app, a right-click that opens nothing and one that opens the WRONG
    /// menu look identical. DesignScaffold 0.8.3 was exactly a menu that stopped presenting in
    /// one selection state while every screenshot of the other state looked perfect.
    public static func menuItem(_ item: String, on target: String) {
        guard isEnabled else { return }
        emit("PROBE MENUITEM \(item) on \(target)")
    }

    /// A committed edit. `kind` distinguishes which callback fired — a trim that commits as a
    /// move is a silent wrong answer, and silence is how a non-committing drag presents.
    public static func commit(_ kind: String, _ target: String, _ detail: String = "") {
        guard isEnabled else { return }
        emit("PROBE COMMIT \(kind) \(target)\(detail.isEmpty ? "" : " " + detail)")
    }
}

// MARK: - View integration

private struct HitTestProbeModifier: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { proxy in
                // ⚠️ Re-report on CHANGE, not just `onAppear`. A frame captured once goes stale
                // the moment an edit resizes the element, and a harness clicking a stale centre
                // lands on a neighbour and blames the component.
                Color.clear
                    .onAppear { HitTestProbe.record(name: name, frame: proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, frame in
                        HitTestProbe.record(name: name, frame: frame)
                    }
            }
            // A probe that swallowed a click would be a hit-testing bug inside the hit-testing
            // instrument.
            .allowsHitTesting(false)
        }
    }
}

public extension View {
    /// Report this view's drawn frame under `name`, for `Tools/InputDriver` to click.
    ///
    /// Inert unless the probe is enabled, so it is safe to leave at a call site.
    func hitTestProbe(_ name: String) -> some View {
        modifier(HitTestProbeModifier(name: name))
    }
}
