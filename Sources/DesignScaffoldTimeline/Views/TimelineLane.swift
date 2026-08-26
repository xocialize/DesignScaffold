import DesignScaffold
import SwiftUI

/// One track's clip lane. Positions and sizes clips through the shared geometry, hands the
/// inside to the consumer's `ViewBuilder`, and owns the T2 gestures — drag (including
/// across tracks) and edge-drag trim.
///
/// Gestures compute a *result* and report it; the lane never mutates the consumer's model.
/// While a drag is live the clip follows the cursor from local state, so the edit previews
/// without the host having to round-trip every frame.
struct TimelineLane<Clip: TimelineClip, TrackID: Hashable, Body: View>: View {
    let track: TimelineTrack<TrackID>
    let trackIndex: Int
    let clips: [Clip]
    let geometry: TimelineGeometry
    let theme: TimelineTheme
    let isAlternate: Bool
    let selection: Set<Clip.ID>
    /// In-flight edit owned by the parent, so a clip dragged onto another track renders in
    /// the destination lane rather than being clipped by its origin lane.
    let draft: TimelineDraft<Clip.ID>?
    let onSelect: (Clip.ID, Bool) -> Void
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
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    Color.clear
                    ForEach(visibleClips) { clip in
                        clipView(clip)
                    }
                }
            }
            .clipped()
    }

    /// Clips that render in THIS lane: those belonging to it, minus one being dragged away,
    /// plus one being dragged in. Virtualised against the viewport.
    private var visibleClips: [Clip] {
        clips.filter { clip in
            let placed = resolved(clip)
            guard placed.trackIndex == trackIndex else { return false }
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
            .gesture(
                DragGesture(minimumDistance: 3)
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
            .gesture(
                DragGesture(minimumDistance: 2)
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
