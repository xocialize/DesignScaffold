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
import DesignScaffoldProbe
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

/// The lab's probe is now `DesignScaffoldProbe`'s.
///
/// It used to be a second implementation, which is how it acquired a bug the other copy did
/// not have and missed a fix the other copy did have. The shared version is the union: ML[X]
/// LTX Studio's coalescing and outcome vocabulary, this one's `ViewModifier` ergonomics, and
/// the removed non-zero guard that was hiding collapsed frames.
extension View {
    /// Report this view's drawn frame in screen space under `name`.
    func drawnFrameProbe(_ name: String) -> some View { hitTestProbe(name) }

    /// Log every selection change as a single line, for a driver to assert on.
    func logSelection<S: Hashable>(_ label: String, _ selection: Set<S>) -> some View {
        onChange(of: selection) { _, now in
            let ids = now.map { String(describing: $0) }.sorted()
            LabLog.shared.note("SELECT \(label) [\(ids.isEmpty ? "none" : ids.joined(separator: ","))]")
            HitTestProbe.selection(ids)
        }
    }
}
