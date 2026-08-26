import DesignScaffold
import SwiftUI

/// A media-agnostic multi-track timeline: ruler, track headers, clip lanes, playhead,
/// with drag, cross-track move, edge trim and snapping.
///
/// ```swift
/// TimelineView(tracks: tracks, clips: clips,
///              geometry: $geometry, playhead: $playhead, selection: $selection) { clip in
///     Filmstrip(clip.asset)          // the consumer draws the inside
/// }
/// .snapSources([.clipEdges(clips), .playhead(playhead), .origin])
/// .onMove { id, start, track in document.move(id, to: start, on: track) }
/// .onTrim { id, start, duration in document.retime(id, start, duration) }
/// ```
///
/// **Scope.** The scaffold owns the chrome and the gestures; what a clip *means* stays with
/// the consumer. The tool rail on the spec artboard is app chrome and is deliberately not
/// built here.
///
/// **Everything derives from one ``TimelineGeometry``**, so ruler, headers and lanes cannot
/// drift out of sync — there are no scroll offsets to reconcile, and virtualisation falls
/// out of the same choice. Panning and zooming are writes to that one value.
///
/// T3 adds in/out brackets, gap indicators, marquee select and row-height resize.
public struct TimelineView<Clip: TimelineClip, TrackID: Hashable, ClipBody: View, HeaderAccessory: View>: View {

    let tracks: [TimelineTrack<TrackID>]
    let clips: [Clip]
    @Binding var geometry: TimelineGeometry
    @Binding var playhead: TimeInterval
    @Binding var selection: Set<Clip.ID>

    var themeOverride: TimelineTheme?
    var timecode = Timecode()
    var snapSources: [TimelineSnapSource] = []
    var minimumClipDuration: TimeInterval = 0.1
    var onToggleControl: ((TimelineTrack<TrackID>, TimelineTrack<TrackID>.Control) -> Void)?
    var onMove: ((Clip.ID, TimeInterval, Int) -> Void)?
    var onTrim: ((Clip.ID, TimeInterval, TimeInterval) -> Void)?

    let clipBody: (Clip) -> ClipBody
    let headerAccessory: (TimelineTrack<TrackID>) -> HeaderAccessory

    /// The edit currently under the cursor, if any.
    @State private var draft: TimelineDraft<Clip.ID>?

    var theme: TimelineTheme { themeOverride ?? .scaffold }

    public init(
        tracks: [TimelineTrack<TrackID>],
        clips: [Clip],
        geometry: Binding<TimelineGeometry>,
        playhead: Binding<TimeInterval>,
        selection: Binding<Set<Clip.ID>>,
        @ViewBuilder clipBody: @escaping (Clip) -> ClipBody,
        @ViewBuilder headerAccessory: @escaping (TimelineTrack<TrackID>) -> HeaderAccessory
    ) {
        self.tracks = tracks
        self.clips = clips
        self._geometry = geometry
        self._playhead = playhead
        self._selection = selection
        self.clipBody = clipBody
        self.headerAccessory = headerAccessory
    }

    public var body: some View {
        GeometryReader { proxy in
            let laneWidth = max(0, proxy.size.width - theme.headerWidth)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    playheadReadout
                    verticalRule(height: theme.rulerHeight)
                    TimelineRuler(geometry: geometry, timecode: timecode, theme: theme,
                                  onScrub: { playhead = $0 })
                }
                .frame(height: theme.rulerHeight)
                horizontalRule
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            HStack(spacing: 0) {
                                TimelineTrackHeader(track: track, theme: theme,
                                                    onToggle: { onToggleControl?(track, $0) }) {
                                    headerAccessory(track)
                                }
                                verticalRule(height: track.resolvedHeight)
                                lane(track: track, index: index)
                            }
                            .frame(height: track.resolvedHeight)
                            horizontalRule
                        }
                    }
                }
            }
            .overlay(alignment: .topLeading) { playheadLine(laneWidth: laneWidth) }
            .overlay(alignment: .topLeading) { snapIndicator(laneWidth: laneWidth) }
            // Trackpad scroll + pinch, scoped to the lane area so the header column and the
            // rest of the app keep their own scrolling.
            .background(alignment: .topTrailing) {
                TrackpadGestureCatcher(
                    onScroll: { delta in
                        geometry.scroll(to: geometry.visibleStart + geometry.seconds(forPoints: delta))
                    },
                    onMagnify: { magnification, location in
                        let anchor = geometry.time(atX: location.x)
                        geometry.zoom(to: geometry.pointsPerSecond * (1 + magnification),
                                      keeping: anchor)
                        if geometry.visibleStart < 0 { geometry.scroll(to: 0) }
                    })
                .frame(width: laneWidth)
            }
            .background(theme.laneBackground)
            .clipShape(RoundedRectangle(cornerRadius: theme.panelRadius))
            .overlay(
                RoundedRectangle(cornerRadius: theme.panelRadius)
                    .strokeBorder(theme.separator, lineWidth: theme.hairline)
            )
            .onChange(of: proxy.size.width, initial: true) { _, width in
                geometry.viewportWidth = max(0, width - theme.headerWidth)
            }
        }
    }

    // MARK: Lane

    private func lane(track: TimelineTrack<TrackID>, index: Int) -> some View {
        TimelineLane(
            track: track, trackIndex: index, clips: clips,
            geometry: geometry, theme: theme,
            isAlternate: index.isMultiple(of: 2),
            selection: selection, draft: draft,
            isDropTarget: isDropTarget(track: index),
            onSelect: { id, additive in select(id, additive: additive) },
            onBackgroundTap: { selection.removeAll() },
            onDragChanged: { clip, translation in dragChanged(clip, translation) },
            onDragEnded: { commitDraft() },
            onTrimChanged: { clip, edge, dx in trimChanged(clip, edge, dx) },
            onTrimEnded: { commitDraft() },
            clipBody: clipBody)
    }

    /// Whether `track` is the destination of a crossing drag — shown as a tint on that
    /// lane. Deliberately the ONLY cross-track feedback during the gesture: anything that
    /// moves the clip's view between lanes, or toggles a lane's clipping, rebuilds the view
    /// tree and kills the drag (see `TimelineLane.visibleClips`).
    private func isDropTarget(track index: Int) -> Bool {
        guard let draft,
              let origin = clips.first(where: { $0.id == draft.id })?.trackIndex
        else { return false }
        return draft.trackIndex != origin && draft.trackIndex == index
    }

    // MARK: Gestures → geometry-derived edits

    /// A plain click SELECTS; it never deselects.
    ///
    /// It used to clear the selection when you clicked the only selected clip — a tidy
    /// toggle in the abstract, and a footgun in an editor. Selection gates the destructive
    /// commands (delete, ripple delete, re-roll, take-cycling), and clicking a clip you have
    /// already selected is the ordinary reflex *before* pressing one of those keys. The
    /// toggle silently disarmed all of them with no visible cause. Deselection belongs to
    /// the background click and Escape, which is where an editor user looks for it.
    /// (Raised by ML[X] LTX Studio on AB-A-0031, found through their hit-test gate.)
    private func select(_ id: Clip.ID, additive: Bool) {
        if additive {
            if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
        } else {
            selection = [id]
        }
    }

    private func dragChanged(_ clip: Clip, _ translation: CGSize) {
        let deltaTime = geometry.seconds(forPoints: translation.width)
        let deltaTracks = TimelineEdit.trackDelta(
            from: clip.trackIndex, verticalTranslation: translation.height,
            heights: tracks.map(\.resolvedHeight))
        let moved = TimelineEdit.move(
            start: clip.start, trackIndex: clip.trackIndex,
            deltaTime: deltaTime, deltaTracks: deltaTracks, trackCount: tracks.count)

        // Snap tolerance is POINTS converted at the current zoom — never a stored duration.
        let tolerance = geometry.seconds(forPoints: theme.snapThreshold)
        let candidates = TimelineSnap.candidates(from: snapSources, in: geometry.visibleRange)
        let snapped = TimelineSnap.snapStart(start: moved.start, duration: clip.duration,
                                             candidates: candidates, tolerance: tolerance)
        draft = TimelineDraft(id: clip.id, kind: .move,
                              start: max(0, snapped ?? moved.start),
                              duration: clip.duration,
                              trackIndex: moved.trackIndex,
                              snappedTo: snapped)
    }

    private func trimChanged(_ clip: Clip, _ edge: TimelineEdge, _ dx: CGFloat) {
        let deltaTime = geometry.seconds(forPoints: dx)
        let trimmed = TimelineEdit.trim(start: clip.start, duration: clip.duration,
                                        edge: edge, deltaTime: deltaTime,
                                        minimumDuration: minimumClipDuration)
        let tolerance = geometry.seconds(forPoints: theme.snapThreshold)
        let candidates = TimelineSnap.candidates(from: snapSources, in: geometry.visibleRange)
        // Only the dragged EDGE snaps during a trim — snapping the far edge would move the
        // side the user is holding still.
        let movingEdge = edge == .leading ? trimmed.start : trimmed.start + trimmed.duration
        let snap = TimelineSnap.nearest(to: movingEdge, candidates: candidates, tolerance: tolerance)
        var result = trimmed
        if let snap {
            result = TimelineEdit.trim(
                start: clip.start, duration: clip.duration, edge: edge,
                deltaTime: snap - (edge == .leading ? clip.start : clip.start + clip.duration),
                minimumDuration: minimumClipDuration)
        }
        draft = TimelineDraft(id: clip.id, kind: .trim, start: result.start,
                              duration: result.duration,
                              trackIndex: clip.trackIndex, snappedTo: snap)
    }

    /// Report the finished edit to the host, which owns the document. Nothing fires when
    /// the gesture ended where it started.
    private func commitDraft() {
        defer { draft = nil }
        guard let draft, let original = clips.first(where: { $0.id == draft.id }) else { return }
        switch draft.kind {
        case .move:
            guard draft.start != original.start || draft.trackIndex != original.trackIndex else { return }
            onMove?(draft.id, draft.start, draft.trackIndex)
        case .trim:
            guard draft.start != original.start || draft.duration != original.duration else { return }
            onTrim?(draft.id, draft.start, draft.duration)
        }
    }

    // MARK: Pieces

    private var playheadReadout: some View {
        Text(timecode.exact(playhead))
            .font(theme.timecodeFont)
            .monospacedDigit()
            .foregroundStyle(theme.rulerLabel)
            .frame(width: theme.headerWidth, height: theme.rulerHeight)
            .background(theme.rulerBackground)
            .accessibilityLabel(Text("Playhead"))
            .accessibilityValue(Text(timecode.exact(playhead)))
    }

    @ViewBuilder
    private func playheadLine(laneWidth: CGFloat) -> some View {
        let x = geometry.x(for: playhead)
        if x >= 0, x <= laneWidth {
            Rectangle()
                .fill(theme.playhead)
                .frame(width: theme.playheadWidth)
                .overlay(alignment: .top) {
                    Path { p in
                        p.move(to: CGPoint(x: -4, y: 0))
                        p.addLine(to: CGPoint(x: 5, y: 0))
                        p.addLine(to: CGPoint(x: 0.5, y: 6))
                        p.closeSubpath()
                    }
                    .fill(theme.playhead)
                    .frame(width: 9, height: 6)
                }
                .offset(x: theme.headerWidth + theme.hairline + x)
                .allowsHitTesting(false)
        }
    }

    /// A hairline at the snapped time while a gesture is snapped — without it, snapping is
    /// felt but not seen, and a user cannot tell a snap from a coincidence.
    @ViewBuilder
    private func snapIndicator(laneWidth: CGFloat) -> some View {
        if let snapped = draft?.snappedTo {
            let x = geometry.x(for: snapped)
            if x >= 0, x <= laneWidth {
                Rectangle()
                    .fill(theme.selection)
                    .frame(width: theme.hairline)
                    .offset(x: theme.headerWidth + theme.hairline + x)
                    .allowsHitTesting(false)
            }
        }
    }

    private func verticalRule(height: CGFloat) -> some View {
        Rectangle().fill(theme.separator).frame(width: theme.hairline, height: height)
    }

    private var horizontalRule: some View {
        Rectangle().fill(theme.separator).frame(height: theme.hairline)
    }
}

// MARK: - Convenience initialisers

extension TimelineView where HeaderAccessory == EmptyView {
    /// No app-specific header accessory.
    public init(
        tracks: [TimelineTrack<TrackID>],
        clips: [Clip],
        geometry: Binding<TimelineGeometry>,
        playhead: Binding<TimeInterval>,
        selection: Binding<Set<Clip.ID>>,
        @ViewBuilder clipBody: @escaping (Clip) -> ClipBody
    ) {
        self.init(tracks: tracks, clips: clips, geometry: geometry, playhead: playhead,
                  selection: selection, clipBody: clipBody, headerAccessory: { _ in EmptyView() })
    }
}

// MARK: - Chainable configuration

public extension TimelineView {
    /// Override the visual theme. Without this, ``TimelineTheme/scaffold`` is used.
    func theme(_ theme: TimelineTheme) -> TimelineView {
        var copy = self
        copy.themeOverride = theme
        return copy
    }

    /// Frame rate for the timecode readout and ruler labels.
    func frameRate(_ fps: Double) -> TimelineView {
        var copy = self
        copy.timecode = Timecode(frameRate: fps)
        return copy
    }

    /// Times drags snap to. Empty (the default) disables snapping entirely.
    func snapSources(_ sources: [TimelineSnapSource]) -> TimelineView {
        var copy = self
        copy.snapSources = sources
        return copy
    }

    /// Shortest a clip may be trimmed to.
    func minimumClipDuration(_ duration: TimeInterval) -> TimelineView {
        var copy = self
        copy.minimumClipDuration = duration
        return copy
    }

    /// Called when a header's state control is tapped — the host owns the state.
    func onToggleControl(_ handler: @escaping (TimelineTrack<TrackID>, TimelineTrack<TrackID>.Control) -> Void) -> TimelineView {
        var copy = self
        copy.onToggleControl = handler
        return copy
    }

    /// Committed at the end of a move: the clip's new start and track index.
    func onMove(_ handler: @escaping (Clip.ID, TimeInterval, Int) -> Void) -> TimelineView {
        var copy = self
        copy.onMove = handler
        return copy
    }

    /// Committed at the end of a trim: the clip's new start and duration.
    func onTrim(_ handler: @escaping (Clip.ID, TimeInterval, TimeInterval) -> Void) -> TimelineView {
        var copy = self
        copy.onTrim = handler
        return copy
    }
}
