import DesignScaffold
import SwiftUI

/// A media-agnostic multi-track timeline: ruler, track headers, clip lanes, playhead.
///
/// ```swift
/// TimelineView(tracks: tracks, clips: clips,
///              geometry: $geometry, playhead: $playhead,
///              selection: $selection) { clip in
///     FilmstripBody(clip)          // the consumer draws the inside
/// }
/// ```
///
/// **Scope.** The scaffold owns the chrome and the gestures — ruler and scrub, headers and
/// their state controls, lane layout, the playhead, zoom, and (from T2) selection, drag,
/// trim and snapping. What a clip *means* stays with the consumer: filmstrips, waveforms,
/// take chips, generation overlays. The tool rail on the spec artboard is app chrome and is
/// deliberately not built here — place the timeline beside your own rail.
///
/// **Everything derives from one ``TimelineGeometry``**, so ruler, headers and lanes cannot
/// drift out of sync; there are no scroll offsets to reconcile. Panning and zooming are
/// writes to that one value.
///
/// T1 ships static lanes (layout, selection rendering, tap-select). Drag, cross-track move,
/// edge trim and snapping are T2; brackets, gap indicators, marquee and row resize are T3.
public struct TimelineView<Clip: TimelineClip, ClipBody: View, HeaderAccessory: View>: View {

    let tracks: [TimelineTrack]
    let clips: [Clip]
    @Binding var geometry: TimelineGeometry
    @Binding var playhead: TimeInterval
    @Binding var selection: Set<Clip.ID>

    var themeOverride: TimelineTheme?
    var timecode = Timecode()
    var onToggleControl: ((TimelineTrack, TimelineTrack.Control) -> Void)?

    let clipBody: (Clip) -> ClipBody
    let headerAccessory: (TimelineTrack) -> HeaderAccessory

    var theme: TimelineTheme { themeOverride ?? .scaffold }

    public init(
        tracks: [TimelineTrack],
        clips: [Clip],
        geometry: Binding<TimelineGeometry>,
        playhead: Binding<TimeInterval>,
        selection: Binding<Set<Clip.ID>>,
        @ViewBuilder clipBody: @escaping (Clip) -> ClipBody,
        @ViewBuilder headerAccessory: @escaping (TimelineTrack) -> HeaderAccessory
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
                                TimelineLane(
                                    track: track,
                                    clips: clips.filter { $0.trackIndex == index },
                                    geometry: geometry, theme: theme,
                                    isAlternate: index.isMultiple(of: 2),
                                    selection: selection,
                                    onSelect: { toggle($0) },
                                    clipBody: clipBody)
                            }
                            .frame(height: track.resolvedHeight)
                            horizontalRule
                        }
                    }
                }
            }
            // The playhead spans ruler and lanes, so it is drawn over the whole body
            // rather than per-lane.
            .overlay(alignment: .topLeading) { playheadLine(laneWidth: laneWidth) }
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
                    // The head: a small marker so the line is grabbable and readable
                    // against a busy lane.
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

    /// A vertical hairline. The height is REQUIRED: a `Rectangle` given only a width is
    /// greedy vertically, and in an HStack that silently inflates the whole row — it is
    /// what pushed the last track out of frame in the first render.
    private func verticalRule(height: CGFloat) -> some View {
        Rectangle().fill(theme.separator).frame(width: theme.hairline, height: height)
    }

    private var horizontalRule: some View {
        Rectangle().fill(theme.separator).frame(height: theme.hairline)
    }

    private func toggle(_ id: Clip.ID) {
        if selection.contains(id) { selection.remove(id) } else { selection = [id] }
    }
}

// MARK: - Convenience initialisers

extension TimelineView where HeaderAccessory == EmptyView {
    /// No app-specific header accessory.
    public init(
        tracks: [TimelineTrack],
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

    /// Called when a header's state control is tapped — the host owns the state.
    func onToggleControl(_ handler: @escaping (TimelineTrack, TimelineTrack.Control) -> Void) -> TimelineView {
        var copy = self
        copy.onToggleControl = handler
        return copy
    }
}
