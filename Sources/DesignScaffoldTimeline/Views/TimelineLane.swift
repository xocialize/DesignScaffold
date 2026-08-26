import DesignScaffold
import SwiftUI

/// One track's clip lane. Positions and sizes clips through the shared geometry, hands the
/// inside to the consumer's `ViewBuilder`, and owns the T2 gestures — drag (including
/// across tracks) and edge-drag trim.
///
/// ⚠️ Every drag here is measured in ``TimelineLane/laneSpace``, a FIXED coordinate space on
/// the lane — never the default `.local`. A clip's local space travels with the clip, so a
/// drag on a moving view measures its translation against a frame the previous update just
/// shifted: the value being changed feeds back into its own input, and the clip stutters and
/// jumps instead of tracking the pointer. The lane does not move, so measuring against it is
/// stable no matter where the clip goes.
///
/// Gestures compute a *result* and report it; the lane never mutates the consumer's model.
/// While a drag is live the clip follows the cursor from local state, so the edit previews
/// without the host having to round-trip every frame.
struct TimelineLane<Clip: TimelineClip, TrackID: Hashable, Body: View, GapBody: View>: View {
    /// The fixed frame every drag in this lane is measured against — see the type's note.
    static var laneSpace: String { "DesignScaffoldTimeline.lane" }

    let track: TimelineTrack<TrackID>
    let trackIndex: Int
    let clips: [Clip]
    let geometry: TimelineGeometry
    let theme: TimelineTheme
    let isAlternate: Bool
    let selection: Set<Clip.ID>
    /// In-flight edit owned by the parent.
    let draft: TimelineDraft<Clip.ID>?
    /// True while this lane is the DESTINATION of a crossing drag, so it can show itself as
    /// the drop target. A colour change only — never a structural one.
    let isDropTarget: Bool
    let onSelect: (Clip.ID, Bool) -> Void
    /// Clicking empty lane clears the selection — the counterpart to a plain click never
    /// deselecting. Without it there is no way to deselect at all until T3's marquee.
    let onBackgroundTap: () -> Void
    /// Rubber-band selection. The lane reports raw drag values; the timeline owns the rect,
    /// so the marquee is drawn as a sibling in the parent and never rebuilds this subtree.
    let onMarqueeChanged: (_ startX: CGFloat, _ translation: CGSize, _ fromTrack: Int) -> Void
    let onMarqueeEnded: () -> Void
    @ViewBuilder let gapBody: (TimelineGap) -> GapBody
    let onDragChanged: (Clip, CGSize) -> Void
    let onDragEnded: () -> Void
    let onTrimChanged: (Clip, TimelineEdge, CGFloat) -> Void
    let onTrimEnded: () -> Void
    @ViewBuilder let clipBody: (Clip) -> Body

    var body: some View {
        // Clips live in an OVERLAY, not as ZStack children. Placing them by layout means
        // their extents would otherwise dictate the lane's ideal width — a 13-second edit
        // at 60 pt/s asks for 800pt — which widens the scroll content and shoves the ruler
        // out of alignment with the lanes below it. An overlay is sized by its parent and
        // never reports size upward, so the lane stays exactly as wide as the viewport.
        (isAlternate ? theme.laneAlternate : theme.laneBackground)
            .frame(maxWidth: .infinity, minHeight: track.resolvedHeight,
                   maxHeight: track.resolvedHeight)
            .contentShape(Rectangle())
            .onTapGesture { onBackgroundTap() }
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .named(Self.laneSpace))
                    .onChanged { onMarqueeChanged($0.startLocation.x, $0.translation, trackIndex) }
                    .onEnded { _ in onMarqueeEnded() }
            )
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    // Sizes the stack without swallowing taps meant for the lane behind it.
                    Color.clear.allowsHitTesting(false)
                    ForEach(visibleGaps) { gap in
                        gapView(gap)
                    }
                    ForEach(visibleClips) { clip in
                        clipView(clip)
                    }
                }
            }
            // Highlight, not geometry: the drop target is shown by tinting the destination
            // lane rather than flying the clip across rows. Riding the clip over means either
            // moving its view between lanes or toggling this lane's clipping mid-drag, and
            // BOTH rebuild the view tree and tear down the live gesture — measured twice.
            .overlay(theme.selectionWash.opacity(isDropTarget ? 1 : 0).allowsHitTesting(false))
            .clipped()
            .coordinateSpace(.named(Self.laneSpace))
    }

    /// Clips that render in THIS lane.
    ///
    /// ⚠️ Membership is decided by the clip's OWN `trackIndex`, never the draft's. A clip
    /// being dragged to another track stays rendered here for the whole gesture, displaced
    /// vertically so it appears over its destination.
    ///
    /// Filtering on the draft's track instead — which is what this did until 0.6.2 —
    /// removes the clip's view from this lane the instant a drag crosses a row boundary and
    /// rebuilds it in the destination lane. SwiftUI tears down the gesture attached to the
    /// destroyed view, so the drag silently stops: the preview sticks on the destination
    /// row, `onEnded` never fires, nothing is committed, and the host's model never changes.
    /// Observed exactly that way in interactive testing — the clip appeared to move and no
    /// callback ever arrived.
    private var visibleClips: [Clip] {
        clips.filter { clip in
            guard clip.trackIndex == trackIndex else { return false }
            let placed = resolved(clip)
            return geometry.isVisible(start: placed.start, duration: placed.duration)
        }
    }

    /// A clip's position with any in-flight edit applied.
    private func resolved(_ clip: Clip) -> (start: TimeInterval, duration: TimeInterval, trackIndex: Int) {
        guard let draft, draft.id == clip.id else {
            return (clip.start, clip.duration, clip.trackIndex)
        }
        return (draft.start, draft.duration, draft.trackIndex)
    }

    /// Gaps on this track that intersect the viewport.
    private var visibleGaps: [TimelineGap] {
        TimelineGaps.gaps(in: clips, trackIndex: trackIndex)
            .map { TimelineGap(trackIndex: trackIndex, range: $0) }
            .filter { geometry.isVisible(start: $0.start, duration: $0.duration) }
    }

    private func gapView(_ gap: TimelineGap) -> some View {
        gapBody(gap)
            .frame(width: max(1, geometry.width(for: gap.duration)),
                   height: track.resolvedHeight - theme.clipInset * 2)
            .timelinePlaced(x: geometry.x(for: gap.start), y: theme.clipInset)
    }

    private func clipView(_ clip: Clip) -> some View {
        let placed = resolved(clip)
        let isSelected = selection.contains(clip.id)
        let isDragging = draft?.id == clip.id
        let width = max(theme.trimHandleWidth * 2, geometry.width(for: placed.duration))
        return clipBody(clip)
            .frame(width: width, height: track.resolvedHeight - theme.clipInset * 2)
            .background(theme.clipBackground)
            .overlay { if isSelected { theme.selectionWash } }
            .clipShape(RoundedRectangle(cornerRadius: theme.clipRadius))
            .overlay(
                RoundedRectangle(cornerRadius: theme.clipRadius)
                    .strokeBorder(isSelected ? theme.selection : theme.separator,
                                  lineWidth: isSelected ? 2 : theme.hairline)
            )
            .overlay(alignment: .leading) { trimHandle(clip, edge: .leading) }
            .overlay(alignment: .trailing) { trimHandle(clip, edge: .trailing) }
            .opacity(isDragging ? 0.85 : 1)
            .contentShape(Rectangle())
            // Placed by LAYOUT, never `.offset` — see TimelinePlacement for the bug that
            // rule exists to prevent (hit regions all anchoring at the lane's left edge).
            .timelinePlaced(x: geometry.x(for: placed.start), y: theme.clipInset)
            .onTapGesture { onSelect(clip.id, NSEvent.modifierFlags.contains(.shift)) }
            // minimumDistance keeps a click from registering as a zero-length drag.
            // Measured against the LANE, not the clip: the clip moves as this drag runs.
            .gesture(
                DragGesture(minimumDistance: 3, coordinateSpace: .named(Self.laneSpace))
                    .onChanged { onDragChanged(clip, $0.translation) }
                    .onEnded { _ in onDragEnded() }
            )
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The 8pt edge handle from the spec. Its own drag gesture takes precedence over the
    /// clip's move gesture because it sits above it in the overlay stack.
    private func trimHandle(_ clip: Clip, edge: TimelineEdge) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: theme.trimHandleWidth)
            .contentShape(Rectangle())
            .onHover { inside in
                if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
            }
            // The handle travels with the edge it trims, so the same rule applies.
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .named(Self.laneSpace))
                    .onChanged { onTrimChanged(clip, edge, $0.translation.width) }
                    .onEnded { _ in onTrimEnded() }
            )
    }
}

/// An edit in flight. Held by the timeline while a gesture runs so the preview can cross
/// lanes, and handed to the host on commit.
struct TimelineDraft<ID: Hashable>: Equatable {
    /// Which gesture produced this draft. Recorded rather than inferred: diffing the draft
    /// against the original to guess "move vs trim" misreports the edge cases (a trim that
    /// happens to land on the original duration, a move of exactly zero).
    enum Kind: Equatable { case move, trim }

    let id: ID
    var kind: Kind
    var start: TimeInterval
    var duration: TimeInterval
    var trackIndex: Int
    /// Set when the current position is snapped, so the lane can show it.
    var snappedTo: TimeInterval?
}
