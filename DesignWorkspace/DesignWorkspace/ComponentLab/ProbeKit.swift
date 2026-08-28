//
//  ProbeKit.swift
//  DesignWorkspace — Component Lab
//
//  Verification instruments shared by every harness.
//
//  These exist because of a measured pattern: every defect found in a DesignScaffold
//  component AFTER it compiled was found by a pointer, and none by a headless test. Renders
//  prove placement; unit tests prove arithmetic; neither touches hit testing or gesture
//  lifetime, which is where this library has actually broken.
//

import AppKit
import Combine
import SwiftUI

/// A line-oriented log the harnesses write to and the lab displays.
///
/// Also prints to stdout, so `Tools/InputDriver` runs can assert on it from a script without
/// the window being visible.
@MainActor
final class LabLog: ObservableObject {
    static let shared = LabLog()

    @Published private(set) var lines: [String] = []

    func note(_ message: String) {
        lines.append(message)
        if lines.count > 200 { lines.removeFirst(lines.count - 200) }
        print(message)
        fflush(stdout)
    }

    func clear() { lines.removeAll() }
}

/// Reports where a view was ACTUALLY DRAWN, in the top-left screen space `CGEvent` uses — so
/// a driver clicks what the app drew rather than what someone computed.
///
/// Two rules it encodes, both learned from false defect reports:
///
/// 1. **SwiftUI's `.global` space is window-FRAME relative**, not content-view relative.
///    Adding the title bar again puts every target ~27–34pt too low. That error produced a
///    false report in ML[X] LTX Studio and was reproduced here by hand while proving it.
/// 2. **Re-report on change, not just `onAppear`.** A frame captured once goes stale the
///    moment an edit resizes the element, and a harness clicking a stale centre lands on a
///    trim handle and blames the component.
///
/// It must never intercept a hit: a probe that swallowed clicks would be a hit-testing bug
/// inside the hit-testing instrument.
///
/// ⚠️ **A drawn frame is an upper bound on the hit region, not the hit region.** SwiftUI hit
/// tests against what a view DREW, so padding, a `.background`, and the empty space in a stack
/// are all inside the reported rect and outside the target. Measured in this lab: a sidebar
/// row reported y 609…657 while only 632…650 answered a click, and a labelled `Toggle`'s
/// reported centre landed in the dead gap between its text and its switch. Give anything a
/// driver clicks an explicit `.contentShape(Rectangle())` so the two rects coincide — the
/// probe cannot tell you they differ, only a click can.
struct DrawnFrameProbe: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { report(proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, frame in report(frame) }
            }
            .allowsHitTesting(false)
        }
    }

    private func report(_ frame: CGRect) {
        // ⚠️ NO `frame.width > 0` GUARD. It used to be here, and it made the probe lie in the
        // one case worth seeing: a pane that collapses to zero never reports again, so the
        // probe keeps serving its last non-zero size and a correctly-collapsed pane reads as
        // one that ignored its frame. Measured against WorkspaceSplit, where the arithmetic
        // said `0` and the probe insisted on `103`.
        guard let window = NSApp.keyWindow ?? NSApp.windows.first(where: \.isVisible),
              let mainScreen = NSScreen.screens.first
        else { return }
        // window.frame is bottom-left origin; flip its TOP into top-left screen space.
        let windowTop = mainScreen.frame.maxY - window.frame.maxY
        let centre = CGPoint(x: window.frame.minX + frame.midX, y: windowTop + frame.midY)
        print(String(format: "PROBE %@ centre=(%.0f,%.0f) size=%.0fx%.0f",
                     name, centre.x, centre.y, frame.width, frame.height))
        fflush(stdout)
    }
}

extension View {
    /// Report this view's drawn frame in screen space under `name`.
    func drawnFrameProbe(_ name: String) -> some View {
        modifier(DrawnFrameProbe(name: name))
    }

    /// Log every selection change as a single line, for a driver to assert on.
    func logSelection<S: Hashable>(_ label: String, _ selection: Set<S>) -> some View {
        onChange(of: selection) { _, now in
            let ids = now.map { String(describing: $0) }.sorted().joined(separator: ",")
            LabLog.shared.note("SELECT \(label) [\(ids.isEmpty ? "none" : ids)]")
        }
    }
}
