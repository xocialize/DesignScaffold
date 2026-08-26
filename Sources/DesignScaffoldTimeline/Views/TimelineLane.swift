import DesignScaffold
import SwiftUI

/// One track's clip lane. Positions and sizes clips through the shared geometry and hands
/// the inside to the consumer's `ViewBuilder` — the scaffold never renders clip meaning.
struct TimelineLane<Clip: TimelineClip, Body: View>: View {
    let track: TimelineTrack
    let clips: [Clip]
    let geometry: TimelineGeometry
    let theme: TimelineTheme
    let isAlternate: Bool
    let selection: Set<Clip.ID>
    let onSelect: ((Clip.ID) -> Void)?
    @ViewBuilder let clipBody: (Clip) -> Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            (isAlternate ? theme.laneAlternate : theme.laneBackground)
            // Virtualised: only clips intersecting the viewport are built.
            ForEach(clips.filter { geometry.isVisible(start: $0.start, duration: $0.duration) }) { clip in
                clipView(clip)
            }
        }
        .frame(height: track.resolvedHeight)
        .clipped()
    }

    private func clipView(_ clip: Clip) -> some View {
        let isSelected = selection.contains(clip.id)
        let width = max(2, geometry.width(for: clip.duration))
        return clipBody(clip)
            .frame(width: width, height: track.resolvedHeight - theme.clipInset * 2)
            .background(theme.clipBackground)
            .overlay(alignment: .leading) {
                if isSelected { theme.selectionWash }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.clipRadius))
            .overlay(
                RoundedRectangle(cornerRadius: theme.clipRadius)
                    .strokeBorder(isSelected ? theme.selection : theme.separator,
                                  lineWidth: isSelected ? 2 : theme.hairline)
            )
            .offset(x: geometry.x(for: clip.start), y: theme.clipInset)
            .contentShape(Rectangle())
            .onTapGesture { onSelect?(clip.id) }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
