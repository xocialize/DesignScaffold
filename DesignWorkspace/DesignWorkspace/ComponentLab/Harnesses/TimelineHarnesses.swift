//
//  TimelineHarnesses.swift
//  DesignWorkspace — Component Lab
//

import Combine
import DesignScaffold
import DesignScaffoldTimeline
import SwiftUI

nonisolated struct LabClip: TimelineClip, Sendable {
    let id: Int
    var start: TimeInterval
    var duration: TimeInterval
    var trackIndex: Int
    var label: String
    var tint: [Color]
}

@MainActor
final class LabTimeline: ObservableObject {
    @Published var clips: [LabClip] = [
        .init(id: 1, start: 0, duration: 2.4, trackIndex: 0, label: "A",
              tint: [.blue.opacity(0.8), .blue.opacity(0.5)]),
        .init(id: 2, start: 4.5, duration: 2.4, trackIndex: 0, label: "B",
              tint: [.purple.opacity(0.8), .purple.opacity(0.5)]),
        .init(id: 3, start: 1.0, duration: 3.0, trackIndex: 1, label: "C",
              tint: [.green.opacity(0.8), .green.opacity(0.5)]),
    ]
    @Published var geometry = TimelineGeometry(pointsPerSecond: 60)
    @Published var playhead: TimeInterval = 0
    @Published var selection: Set<Int> = []
    @Published var inOut: ClosedRange<TimeInterval>? = 0.5...7.5
    @Published var heights: [String: CGFloat] = [:]

    var tracks: [TimelineTrack<String>] {
        [TimelineTrack(id: "v1", name: "V1", kind: .video,
                       height: heights["v1"], controls: [.lock, .enable]),
         TimelineTrack(id: "a1", name: "A1", kind: .audio,
                       height: heights["a1"], controls: [.mute, .solo])]
    }

    func move(_ id: Int, start: TimeInterval, track: Int) {
        guard let i = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[i].start = start; clips[i].trackIndex = track
        LabLog.shared.note(String(format: "MOVE %d → %.2f/t%d", id, start, track))
    }
    func trim(_ id: Int, start: TimeInterval, duration: TimeInterval) {
        guard let i = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[i].start = start; clips[i].duration = duration
        LabLog.shared.note(String(format: "TRIM %d → %.2f+%.2f", id, start, duration))
    }
    func resize(_ track: TimelineTrack<String>, to height: CGFloat) {
        let clamped = min(max(24, height), 160)
        guard heights[track.id] != clamped else { return }
        heights[track.id] = clamped
        LabLog.shared.note("RESIZE \(track.name) → \(Int(clamped))pt")
    }
}

/// ⚠️ THE REPRODUCTION HARNESS for AB-A-0031's context-menu report.
///
/// Mirrors ML[X] LTX Studio's call site exactly: an opaque gradient clip body carrying its
/// OWN `.contextMenu`, **and** `.clipContextMenu` attached to the component — which is what
/// their `EditorSpace.swift:462` does. Whichever menu opens identifies the winner.
///
/// A scratchpad `NSHostingView` harness reported the INNER menu winning; their real app sees
/// it never present. If those disagree, the difference is the app, and this is an app.
enum InnerMenuPlacement: String, CaseIterable, Identifiable {
    /// No menu inside `clipBody` at all — ML[X] LTX Studio's actual shape.
    case none = "none"
    /// `.contextMenu` is the LAST thing the host applies.
    case outermost = "outermost"
    /// `.contextMenu` with an `.overlay` applied after it — the shape a hit-test probe,
    /// a badge, or a selection ring gives a clip body without anyone thinking about it.
    case beneathOverlay = "under an overlay"
    /// ML[X] LTX Studio's `clipBody` transcribed from `EditorSpace.swift:488-544`, plus an
    /// inner menu so there is something to win with. Their report is that a menu inside a
    /// body of this shape never presents; this is that claim, executable.
    case ltxVerbatim = "LTX body"
    var id: Self { self }
}

/// ⚠️ THE REPRODUCTION HARNESS for AB-A-0031's context-menu report.
///
/// Two switches, four cells, one click point. Every screenshot is self-labelling because the
/// menu item that opens names which menu won — a verdict that cannot be misread later, unlike
/// "it worked when I tried it".
///
/// Both switches are read at BUILD time of the clip body, which changes view types between
/// cells. That is fine here and nowhere near a gesture: a subtree rebuild between experiments
/// costs nothing, while a rebuild DURING a drag has already produced two wrong diagnoses in
/// this component.
struct TimelineMenuHarness: View {
    @StateObject private var model = LabTimeline()
    @State private var outerAttached = true
    @State private var inner: InnerMenuPlacement = .none

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            // Both controls carry probes, and the cycler is a BUTTON rather than a segmented
            // picker on purpose: a driver that has to guess which third of a picker to hit is
            // guessing coordinates, and a hand-estimated target has already landed 27pt off
            // and produced a false defect report. One probed rect, one click, no arithmetic.
            HStack(spacing: Tokens.Space.l) {
                // Buttons, not a Toggle or a segmented Picker. A probe reports the whole
                // control's rect, and the centre of a LABELLED toggle falls in the gap between
                // its text and its switch — a click there lands on nothing, the state never
                // changes, and every capture after it is silently mislabelled. That happened
                // on the first matrix run. A button's centre is always inside its hit area.
                Button(".clipContextMenu: \(outerAttached ? "attached" : "detached") ⟳") {
                    outerAttached.toggle(); announce()
                }
                .drawnFrameProbe("outer-cycle")
                Button("inside clipBody: \(inner.rawValue) ⟳") {
                    let all = InnerMenuPlacement.allCases
                    inner = all[(all.firstIndex(of: inner)! + 1) % all.count]
                    announce()
                }
                .drawnFrameProbe("inner-cycle")
            }

            Text("Right-click clip A: the item that opens names the winner. Right-click the dashed gap: the control — nothing is layered over gapBody, so its menu must always open. A null result with a dead control means the click never landed, not that the menu is broken.")
                .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            timeline
                .frame(height: 180)
                .logSelection("clip", model.selection)
        }
        .onAppear { announce() }
    }

    /// One canonical line naming BOTH switches, so a capture is named from what the app
    /// reported rather than from what the driver believes it clicked.
    private func announce() {
        LabLog.shared.note("STATE outer=\(outerAttached ? "attached" : "detached") inner=\(inner.rawValue.replacingOccurrences(of: " ", with: "-"))")
    }

    private var timeline: some View {
        let base = TimelineView(
            tracks: model.tracks, clips: model.clips,
            geometry: $model.geometry, playhead: $model.playhead,
            selection: $model.selection,
            clipBody: { clip in clipBody(clip) },
            gapBody: { _ in
                RoundedRectangle(cornerRadius: Tokens.Radius.control)
                    .strokeBorder(Tokens.Color.separator,
                                  style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("GAP — inside gapBody") { LabLog.shared.note("MENU gapBody") }
                    }
                    .drawnFrameProbe("gap")
            })
        return outerAttached
            ? base.clipContextMenu { clip in
                Button("OUTER — clipContextMenu (\(clip.label))") {
                    LabLog.shared.note("MENU outer \(clip.label)")
                }
              }
            : base
    }

    @ViewBuilder
    private func clipBody(_ clip: LabClip) -> some View {
        switch inner {
        case .none:
            // LTX Studio's exact shape: no menu of its own, probe overlay last.
            clipFill(clip).drawnFrameProbe("clip-\(clip.label)")
        case .outermost:
            clipFill(clip)
                .drawnFrameProbe("clip-\(clip.label)")
                .contextMenu { innerItem(clip) }
        case .beneathOverlay:
            clipFill(clip)
                .contextMenu { innerItem(clip) }
                .drawnFrameProbe("clip-\(clip.label)")
        case .ltxVerbatim:
            ltxClipBody(clip)
                .drawnFrameProbe("clip-\(clip.label)")
                .contextMenu { innerItem(clip) }
        }
    }

    private func clipFill(_ clip: LabClip) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: clip.tint, startPoint: .top, endPoint: .bottom)
            Text(clip.label)
                .font(Tokens.Font.monoSmall).foregroundStyle(.white)
                .padding(Tokens.Space.xs)
        }
    }

    /// Transcribed from the consumer's shipping call site, structure for structure: the
    /// greedy inner frame, the colour dot with its stroked overlay, the take line, and the
    /// probe overlay behind an `if`. Running the reporter's own body is the difference
    /// between answering their case and answering a case that resembles it.
    private func ltxClipBody(_ clip: LabClip) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: clip.tint, startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top, spacing: 4) {
                    Circle().fill(.orange).frame(width: 7, height: 7)
                        .overlay { Circle().strokeBorder(.black.opacity(0.35), lineWidth: 0.5) }
                        .padding(.top, 2)
                    Text(clip.label)
                        .font(Tokens.Font.monoSmall).foregroundStyle(.white).shadow(radius: 1)
                }
                Text("take 1/2")
                    .font(Tokens.Font.monoSmall).foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, Tokens.Space.xs)
            .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if true {
                GeometryReader { _ in Color.clear }.allowsHitTesting(false)
            }
        }
    }

    private func innerItem(_ clip: LabClip) -> some View {
        Button("INNER — inside clipBody (\(clip.label))") {
            LabLog.shared.note("MENU inner \(clip.label)")
        }
    }
}

/// Every T2/T3 gesture in one place, with the drawn frames reported so a driver can hit them.
struct TimelineGestureHarness: View {
    @StateObject private var model = LabTimeline()

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            Text("Drag a clip · cross-track · trim an edge · marquee empty lane · drag a bracket · drag a header's bottom edge.")
                .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)

            TimelineView(tracks: model.tracks, clips: model.clips,
                         geometry: $model.geometry, playhead: $model.playhead,
                         selection: $model.selection) { clip in
                ZStack {
                    LinearGradient(colors: clip.tint, startPoint: .top, endPoint: .bottom)
                    Text(clip.label).font(Tokens.Font.body.weight(.bold)).foregroundStyle(.white)
                }
                .drawnFrameProbe("clip-\(clip.label)")
            }
            .inOut($model.inOut)
            .snapSources([.clipEdges(model.clips), .origin])
            .onMove { id, start, track in model.move(id, start: start, track: track) }
            .onTrim { id, start, duration in model.trim(id, start: start, duration: duration) }
            .onResizeTrack { track, height in model.resize(track, to: height) }
            .frame(height: 200)
            .logSelection("clip", model.selection)
        }
    }
}
