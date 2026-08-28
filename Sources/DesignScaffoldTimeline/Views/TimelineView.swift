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
public struct TimelineView<Clip: TimelineClip, TrackID: Hashable, ClipBody: View, GapBody: View, HeaderAccessory: View>: View {

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
    var onResizeTrack: ((TimelineTrack<TrackID>, CGFloat) -> Void)?
    /// In/out brackets. `nil` hides them; dragging a bracket writes back through this.
    var inOut: Binding<ClosedRange<TimeInterval>?>?
    /// Type-erased so adding a menu does not cost the view another generic parameter.
    var clipMenu: ((Clip) -> AnyView)?

    let clipBody: (Clip) -> ClipBody
    let gapBody: (TimelineGap) -> GapBody
    let headerAccessory: (TimelineTrack<TrackID>) -> HeaderAccessory

    /// The edit currently under the cursor, if any.
    @State private var draft: TimelineDraft<Clip.ID>?
    /// Live rubber-band selection, owned here so it draws as a sibling of the lanes rather
    /// than inside one — a marquee rendered in the lane would rebuild the subtree that owns
    /// the drag, which is the failure mode that cost two releases.
    @State private var marquee: MarqueeState?
    /// Where a bracket sat when its drag began.
    ///
    /// A cumulative `DragGesture` translation must be applied to the value at gesture START,
    /// never to the current one. Basing it on the current value feeds the result back into
    /// its own input every frame: the bracket fights itself and creeps instead of tracking
    /// the pointer. (Observed as "the blue lines move but only barely and not freely".)
    @State private var bracketDragStart: TimeInterval?

    struct MarqueeState: Equatable {
        var times: ClosedRange<TimeInterval>
        var tracks: ClosedRange<Int>
    }

    var theme: TimelineTheme { themeOverride ?? .scaffold }

    public init(
        tracks: [TimelineTrack<TrackID>],
        clips: [Clip],
        geometry: Binding<TimelineGeometry>,
        playhead: Binding<TimeInterval>,
        selection: Binding<Set<Clip.ID>>,
        @ViewBuilder clipBody: @escaping (Clip) -> ClipBody,
        @ViewBuilder gapBody: @escaping (TimelineGap) -> GapBody,
        @ViewBuilder headerAccessory: @escaping (TimelineTrack<TrackID>) -> HeaderAccessory
    ) {
        self.tracks = tracks
        self.clips = clips
        self._geometry = geometry
        self._playhead = playhead
        self._selection = selection
        self.clipBody = clipBody
        self.gapBody = gapBody
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
                                header(track)
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
            .overlay(alignment: .topLeading) { inOutBrackets(laneWidth: laneWidth) }
            .overlay(alignment: .topLeading) { marqueeRect(laneWidth: laneWidth) }
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

    // MARK: Header

    /// Hoisted out of `body`: the resize closure built inline defeated the type-checker.
    private func header(_ track: TimelineTrack<TrackID>) -> some View {
        // The header hands back an ABSOLUTE height, computed from the height at gesture
        // start — same rule as the brackets. Adding a cumulative delta to the live height
        // feeds the result back into its own input and the row creeps a point at a time.
        let resize: ((CGFloat) -> Void)? = onResizeTrack.map { handler in
            { height in handler(track, max(theme.rulerHeight, height)) }
        }
        return TimelineTrackHeader(track: track, theme: theme,
                                   onToggle: { onToggleControl?(track, $0) },
                                   onResize: resize) {
            headerAccessory(track)
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
            onMarqueeChanged: { startX, translation, fromTrack in
                marqueeChanged(startX: startX, translation: translation, fromTrack: fromTrack)
            },
            onMarqueeEnded: { marquee = nil },
            gapBody: gapBody,
            onDragChanged: { clip, translation in dragChanged(clip, translation) },
            onDragEnded: { commitDraft() },
            onTrimChanged: { clip, edge, dx in trimChanged(clip, edge, dx) },
            onTrimEnded: { commitDraft() },
            clipMenu: clipMenu,
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

    /// Snap candidates for an edit of `clip`, with **the clip's own edges removed**.
    ///
    /// A clip must not snap to itself. Its own head and tail are in the candidate set that
    /// `.clipEdges(clips)` produces, so without this the clip sticks to its origin, and
    /// worse, its head snaps to its own tail — observed as a drag landing exactly on the
    /// clip's own end. The result is a movement that sticks and jumps instead of tracking
    /// the pointer.
    ///
    /// The component does this rather than the consumer because only the component knows
    /// which clip is being dragged; `.clipEdges(_:excluding:)` exists for callers who want
    /// to build the exclusion themselves, but nobody should have to.
    private func snapCandidates(excluding clip: Clip) -> [TimeInterval] {
        let epsilon = 1e-9
        return TimelineSnap.candidates(from: snapSources, in: geometry.visibleRange)
            .filter { abs($0 - clip.start) > epsilon && abs($0 - clip.end) > epsilon }
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
        // SNAP ON RELEASE, NOT WHILE DRAGGING. The clip follows the pointer exactly; the
        // candidate it would land on is only PREVIEWED as a hairline. Snapping live means
        // the position is being rewritten every frame while the pointer is also moving it —
        // two things writing one value — and no amount of direction-limiting or hysteresis
        // makes that feel smooth. Tried both; it stayed jittery until the snap moved to
        // release.
        let preview = TimelineSnap.snap(
            start: moved.start, duration: clip.duration,
            candidates: snapCandidates(excluding: clip),
            tolerance: geometry.seconds(forPoints: theme.snapThreshold))
        draft = TimelineDraft(id: clip.id, kind: .move,
                              start: max(0, moved.start),
                              duration: clip.duration,
                              trackIndex: moved.trackIndex,
                              snappedTo: preview?.candidate)
    }

    private func trimChanged(_ clip: Clip, _ edge: TimelineEdge, _ dx: CGFloat) {
        let deltaTime = geometry.seconds(forPoints: dx)
        let trimmed = TimelineEdit.trim(start: clip.start, duration: clip.duration,
                                        edge: edge, deltaTime: deltaTime,
                                        minimumDuration: minimumClipDuration)
        // Previewed, not applied — same rule as a move. Only the dragged EDGE is a
        // candidate; snapping the far edge would move the side being held still.
        let movingEdge = edge == .leading ? trimmed.start : trimmed.start + trimmed.duration
        let preview = TimelineSnap.nearest(
            to: movingEdge, candidates: snapCandidates(excluding: clip),
            tolerance: geometry.seconds(forPoints: theme.snapThreshold))
        draft = TimelineDraft(id: clip.id, kind: .trim, start: trimmed.start,
                              duration: trimmed.duration,
                              trackIndex: clip.trackIndex, snappedTo: preview)
    }

    /// Report the finished edit to the host, which owns the document. **This is where
    /// snapping is applied** — the drag itself never moves the clip off the pointer, so the
    /// snap happens once, with nothing left to fight it. Nothing fires when the gesture
    /// ended where it started.
    private func commitDraft() {
        defer { draft = nil }
        guard let draft, let original = clips.first(where: { $0.id == draft.id }) else { return }
        let tolerance = geometry.seconds(forPoints: theme.snapThreshold)
        let candidates = snapCandidates(excluding: original)

        switch draft.kind {
        case .move:
            // Nearest wins on release — no direction filter, because there is no longer a
            // live drag for a backwards snap to fight.
            let landed = TimelineSnap.snap(start: draft.start, duration: draft.duration,
                                           candidates: candidates, tolerance: tolerance)
            let start = max(0, landed?.start ?? draft.start)
            guard start != original.start || draft.trackIndex != original.trackIndex else { return }
            onMove?(draft.id, start, draft.trackIndex)

        case .trim:
            let edge: TimelineEdge = draft.start != original.start ? .leading : .trailing
            let movingEdge = edge == .leading ? draft.start : draft.start + draft.duration
            var result = (start: draft.start, duration: draft.duration)
            if let snap = TimelineSnap.nearest(to: movingEdge, candidates: candidates,
                                               tolerance: tolerance) {
                result = TimelineEdit.trim(
                    start: original.start, duration: original.duration, edge: edge,
                    deltaTime: snap - (edge == .leading ? original.start : original.end),
                    minimumDuration: minimumClipDuration)
            }
            guard result.start != original.start || result.duration != original.duration else { return }
            onTrim?(draft.id, result.start, result.duration)
        }
    }

    // MARK: Marquee

    private func marqueeChanged(startX: CGFloat, translation: CGSize, fromTrack: Int) {
        let startTime = geometry.time(atX: startX)
        let endTime = geometry.time(atX: startX + translation.width)
        let trackDelta = TimelineEdit.trackDelta(from: fromTrack,
                                                 verticalTranslation: translation.height,
                                                 heights: tracks.map(\.resolvedHeight))
        let endTrack = min(max(0, fromTrack + trackDelta), max(0, tracks.count - 1))
        let state = MarqueeState(times: TimelineMarquee.range(from: startTime, to: endTime),
                                 tracks: TimelineMarquee.range(from: fromTrack, to: endTrack))
        marquee = state
        selection = TimelineMarquee.selection(in: clips, times: state.times, tracks: state.tracks)
    }

    @ViewBuilder
    private func marqueeRect(laneWidth: CGFloat) -> some View {
        if let marquee {
            let x0 = max(0, geometry.x(for: marquee.times.lowerBound))
            let x1 = min(laneWidth, geometry.x(for: marquee.times.upperBound))
            let heights = tracks.map(\.resolvedHeight)
            let top = heights.prefix(marquee.tracks.lowerBound).reduce(0, +)
                + CGFloat(marquee.tracks.lowerBound) * theme.hairline
            let height = heights[marquee.tracks].reduce(0, +)
            if x1 > x0 {
                Rectangle()
                    .fill(theme.selection.opacity(0.12))
                    .overlay(Rectangle().strokeBorder(theme.selection, lineWidth: theme.hairline))
                    .frame(width: x1 - x0, height: height)
                    .offset(x: theme.headerWidth + theme.hairline + x0,
                            y: theme.rulerHeight + theme.hairline + top)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: In/out brackets

    @ViewBuilder
    private func inOutBrackets(laneWidth: CGFloat) -> some View {
        if let inOut, let range = inOut.wrappedValue {
            // ⚠️ Identity is which bracket this IS (in vs out) — NEVER its time.
            //
            // Keying identity on the time keys it on the value this gesture mutates: the
            // bracket moves, its identity changes, SwiftUI destroys and rebuilds the view,
            // and the drag it was carrying dies. Observed as one jump and then nothing.
            // Third variant of the same failure in this component, after moving a clip's
            // view between lanes and flipping a @ViewBuilder branch.
            ForEach([true, false], id: \.self) { isIn in
                let time = isIn ? range.lowerBound : range.upperBound
                let x = geometry.x(for: time)
                // Off-screen is hidden by VALUE, not by an `if` — a structural conditional
                // here would rebuild the subtree the moment a bracket left the viewport.
                TimelineBracket(isIn: isIn, theme: theme)
                        .opacity(x >= 0 && x <= laneWidth ? 1 : 0)
                        .allowsHitTesting(x >= 0 && x <= laneWidth)
                        .offset(x: theme.headerWidth + theme.hairline + x)
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    let base = bracketDragStart ?? time
                                    if bracketDragStart == nil { bracketDragStart = time }
                                    let t = max(0, base + geometry.seconds(forPoints: value.translation.width))
                                    let other = isIn ? range.upperBound : range.lowerBound
                                    inOut.wrappedValue = TimelineMarquee.range(from: t, to: other)
                                }
                                .onEnded { _ in bracketDragStart = nil })
            }
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
    /// The snap hairline. Shown and hidden by OPACITY, never by an `if` — a structural
    /// toggle here rebuilds this overlay every time snapping engages or releases, which is
    /// several times a second during a drag.
    private func snapIndicator(laneWidth: CGFloat) -> some View {
        let snapped = draft?.snappedTo
        let x = snapped.map { geometry.x(for: $0) } ?? 0
        let visible = snapped != nil && x >= 0 && x <= laneWidth
        return Rectangle()
            .fill(theme.selection)
            .frame(width: theme.hairline)
            .opacity(visible ? 1 : 0)
            .offset(x: theme.headerWidth + theme.hairline + x)
            .allowsHitTesting(false)
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
    /// A consumer-drawn gap, no header accessory.
    public init(
        tracks: [TimelineTrack<TrackID>],
        clips: [Clip],
        geometry: Binding<TimelineGeometry>,
        playhead: Binding<TimeInterval>,
        selection: Binding<Set<Clip.ID>>,
        @ViewBuilder clipBody: @escaping (Clip) -> ClipBody,
        @ViewBuilder gapBody: @escaping (TimelineGap) -> GapBody
    ) {
        self.init(tracks: tracks, clips: clips, geometry: geometry, playhead: playhead,
                  selection: selection, clipBody: clipBody, gapBody: gapBody,
                  headerAccessory: { _ in EmptyView() })
    }
}

extension TimelineView where HeaderAccessory == EmptyView, GapBody == TimelineGapIndicator {
    /// The scaffold's own gap mark, no header accessory — the simplest form.
    public init(
        tracks: [TimelineTrack<TrackID>],
        clips: [Clip],
        geometry: Binding<TimelineGeometry>,
        playhead: Binding<TimeInterval>,
        selection: Binding<Set<Clip.ID>>,
        @ViewBuilder clipBody: @escaping (Clip) -> ClipBody
    ) {
        let resolved = TimelineTheme.scaffold
        self.init(tracks: tracks, clips: clips, geometry: geometry, playhead: playhead,
                  selection: selection, clipBody: clipBody,
                  gapBody: { _ in TimelineGapIndicator(theme: resolved) },
                  headerAccessory: { _ in EmptyView() })
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

    /// In/out brackets. Omit to hide them.
    func inOut(_ binding: Binding<ClosedRange<TimeInterval>?>) -> TimelineView {
        var copy = self
        copy.inOut = binding
        return copy
    }

    /// Right-click menu for a clip.
    ///
    /// This exists because a `.contextMenu` the host attaches inside `clipBody` presents only
    /// when the host's own content is **hit-testable at the click point** — and a clip body
    /// often is not (a filmstrip with transparent regions, an image still loading, anything
    /// carrying `allowsHitTesting(false)`).
    ///
    /// The failure is silent and looks like the component's fault, because a LEFT click at the
    /// same point still selects the clip: that is answered by the lane's own
    /// `contentShape(Rectangle())`, which covers the whole rect no matter what the host drew.
    /// So the host sees a clip that selects but will not show a menu.
    ///
    /// Measured, after a wrong first explanation: a clip body drawing an opaque fill shows the
    /// host's inner menu; the identical body with nothing hit-testable shows nothing, and this
    /// modifier's menu instead. Attaching here gives a guaranteed hit region regardless of what
    /// the host draws, and the host supplies only the items — the same split as `clipBody`.
    ///
    /// ```swift
    /// .clipContextMenu { clip in
    ///     Button("Regenerate") { regenerate(clip) }
    ///     Button("Delete", role: .destructive) { delete(clip) }
    /// }
    /// ```
    ///
    /// A menu inside `gapBody` is unaffected — nothing sits above gap content — so gaps need
    /// no equivalent.
    func clipContextMenu<Items: View>(@ViewBuilder _ items: @escaping (Clip) -> Items) -> TimelineView {
        var copy = self
        copy.clipMenu = { AnyView(items($0)) }
        return copy
    }

    /// Committed as a track header's bottom edge is dragged — the host owns row height.
    func onResizeTrack(_ handler: @escaping (TimelineTrack<TrackID>, CGFloat) -> Void) -> TimelineView {
        var copy = self
        copy.onResizeTrack = handler
        return copy
    }
}
