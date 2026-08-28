//
//  MenuPrecedenceProbe.swift
//  DesignScaffold — a drop-in diagnostic, not part of any product
//
//  ⚠️ COPY THIS FILE INTO YOUR APP. Do not adapt it, do not restyle it, do not "simplify" the
//  bits that look redundant. Its entire value is that the SAME source runs in two apps, so a
//  difference in result can only be the app.
//
//  Why it exists: DesignScaffoldTimeline's clip context-menu precedence measured INVERTED
//  between two apps on the same machine, against byte-identical component source — an inner
//  `.contextMenu` winning in one and losing in the other. Chronology, view ancestry, hosting
//  class, the drag gestures, the App Sandbox and the menu bar have all been eliminated as
//  variables, in one app or the other or both. What has NOT been eliminated is "something
//  about the app", because until now the two sides ran different harness code.
//
//  Usage — from a debug menu item, or anywhere with a main-thread moment:
//
//      MenuPrecedenceProbe.present()
//
//  Then right-click clip A in each of the four configurations the buttons cycle through, and
//  read stdout. Every line is self-identifying: the menu item that opens names which menu won,
//  so a capture cannot be misread later, and a run cannot be confused with a different cell.
//
//  Deliberately dependency-free beyond the package itself: no logging kit, no probe kit, no
//  app singletons. If it needs something your app has, it stops being a controlled comparison.
//

import AppKit
import DesignScaffold
import DesignScaffoldTimeline
import SwiftUI

// MARK: - Fixture

/// `nonisolated` because a host built with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` would
/// otherwise give this a main-actor-bound `TimelineClip` conformance, which cannot satisfy the
/// component's `Sendable` requirement on its clip type.
nonisolated struct ProbeClip: TimelineClip, Sendable {
    let id: Int
    var start: TimeInterval
    var duration: TimeInterval
    var trackIndex: Int
    var label: String
    var tint: [Color]
}

/// Where a menu inside `clipBody` sits relative to everything else the host applies.
enum ProbeInnerMenu: String, CaseIterable, Identifiable {
    case none = "none"
    case outermost = "outermost"
    case beneathOverlay = "under-an-overlay"
    var id: Self { self }
}

// MARK: - The probe

@MainActor
public enum MenuPrecedenceProbe {
    private static var window: NSWindow?

    /// Opens the probe in its own window. Calling again brings the existing one forward.
    public static func present() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "Menu precedence probe"
        // `sizingOptions = []` — otherwise the hosting view pushes SwiftUI's ideal height into
        // the window and it can open taller than the screen.
        let host = NSHostingView(rootView: MenuPrecedenceProbeView())
        host.sizingOptions = []
        window.contentView = host
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        Self.window = window
        note("PROBE READY  mainMenu=\(NSApp.mainMenu == nil ? "none" : "installed")  sandboxed=\(ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil)")
    }

    static func note(_ message: String) {
        print("MENUPROBE \(message)")
        fflush(stdout)
    }
}

struct MenuPrecedenceProbeView: View {
    @State private var clips: [ProbeClip] = [
        .init(id: 1, start: 0, duration: 2.4, trackIndex: 0, label: "A",
              tint: [.blue.opacity(0.8), .blue.opacity(0.5)]),
        .init(id: 2, start: 4.5, duration: 2.4, trackIndex: 0, label: "B",
              tint: [.purple.opacity(0.8), .purple.opacity(0.5)]),
    ]
    @State private var geometry = TimelineGeometry(pointsPerSecond: 60)
    @State private var playhead: TimeInterval = 0
    @State private var selection: Set<Int> = []
    @State private var outerAttached = true
    @State private var inner: ProbeInnerMenu = .outermost

    private var tracks: [TimelineTrack<String>] {
        [TimelineTrack(id: "v1", name: "V1", kind: .video, controls: [.lock, .enable])]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            // Buttons rather than a Toggle or a segmented Picker: a `.plain` control's hit
            // region is its label's DRAWN content, and a labelled Toggle's centre falls in the
            // dead gap between its text and its switch — where a driver's click lands on
            // nothing and every capture after it is silently mislabelled.
            HStack(spacing: Tokens.Space.l) {
                Button("clipContextMenu: \(outerAttached ? "attached" : "detached") ⟳") {
                    outerAttached.toggle(); announce()
                }
                Button("inside clipBody: \(inner.rawValue) ⟳") {
                    let all = ProbeInnerMenu.allCases
                    inner = all[(all.firstIndex(of: inner)! + 1) % all.count]
                    announce()
                }
            }
            Text("Right-click clip A. The item that opens names which menu won. Right-click the dashed gap as a control — nothing is layered over gapBody, so its menu must always open; a null result with a dead control means the click never landed.")
                .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            timeline.frame(height: 130)

            Text("Every line is printed to stdout with a MENUPROBE prefix.")
                .font(Tokens.Font.monoSmall).foregroundStyle(Tokens.Color.tertiaryLabel)
            Spacer(minLength: 0)
        }
        .padding(Tokens.Space.l)
        .onAppear { announce() }
    }

    private var timeline: some View {
        let base = TimelineView(
            tracks: tracks, clips: clips,
            geometry: $geometry, playhead: $playhead, selection: $selection,
            clipBody: { clip in clipBody(clip) },
            gapBody: { _ in
                RoundedRectangle(cornerRadius: Tokens.Radius.control)
                    .strokeBorder(Tokens.Color.separator,
                                  style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("GAP — inside gapBody") {
                            MenuPrecedenceProbe.note("MENU gapBody")
                        }
                    }
            })
        return outerAttached
            ? base.clipContextMenu { clip in
                Button("OUTER — clipContextMenu (\(clip.label))") {
                    MenuPrecedenceProbe.note("MENU outer \(clip.label)")
                }
              }
            : base
    }

    @ViewBuilder
    private func clipBody(_ clip: ProbeClip) -> some View {
        switch inner {
        case .none:
            clipFill(clip)
        case .outermost:
            clipFill(clip).contextMenu { innerItem(clip) }
        case .beneathOverlay:
            clipFill(clip)
                .contextMenu { innerItem(clip) }
                .overlay { Color.clear.allowsHitTesting(false) }
        }
    }

    private func clipFill(_ clip: ProbeClip) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: clip.tint, startPoint: .top, endPoint: .bottom)
            Text(clip.label)
                .font(Tokens.Font.monoSmall).foregroundStyle(.white)
                .padding(Tokens.Space.xs)
        }
    }

    private func innerItem(_ clip: ProbeClip) -> some View {
        Button("INNER — inside clipBody (\(clip.label))") {
            MenuPrecedenceProbe.note("MENU inner \(clip.label)")
        }
    }

    /// One canonical line naming every variable, so a capture is labelled from what the app
    /// reported rather than from what the person clicking believes they set.
    private func announce() {
        MenuPrecedenceProbe.note("STATE outer=\(outerAttached ? "attached" : "detached") inner=\(inner.rawValue)")
    }
}
