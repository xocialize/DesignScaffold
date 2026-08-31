//
//  ⚠️ macOS-only, and only because `@Previewable` is iOS 17+. This is DEVELOPMENT code —
//  guarding it keeps the package's iOS floor at 16, where the SHIPPING code actually sits,
//  instead of letting a preview macro set the floor for every consumer. See Docs/PLATFORMS.md.
//
#if os(macOS)

//  PlaylistIterator+Previews.swift
//  Canvas gallery for the iterator on the scaffold's card surface, which is how fleet
//  apps host it. No theme calls: the scaffold look IS the default.

import DesignScaffold
import SwiftUI

private struct DemoClip: Identifiable, Equatable {
    let id: Int
    var name: String
    var start: String
    var runtime: String
    var hue: Double
}

private let demoClips: [DemoClip] = [
    DemoClip(id: 1, name: "Lobby Welcome Loop", start: "00:00:00", runtime: "00:00:12", hue: 0.58),
    DemoClip(id: 2, name: "Menu Board — Breakfast", start: "00:00:12", runtime: "00:00:08", hue: 0.10),
    DemoClip(id: 3, name: "Seasonal Promo (4K)", start: "00:00:20", runtime: "00:00:30", hue: 0.33),
    DemoClip(id: 4, name: "Wayfinding — North Hall", start: "00:00:50", runtime: "00:00:15", hue: 0.78),
    DemoClip(id: 5, name: "Sponsor Reel", start: "00:01:05", runtime: "00:00:45", hue: 0.02),
]

#Preview("Playlist, on card") {
    @Previewable @State var clips = demoClips
    @Previewable @State var selectedId: Int? = 3
    PlaylistIterator(
        items: $clips,
        selection: $selectedId,
        active: clips.first?.id,
        name: { $0.name },
        metadata: { [PlaylistMetadatum("Start", $0.start), PlaylistMetadatum("TRT", $0.runtime)] }
    ) { clip in
        LinearGradient(colors: [SwiftUI.Color(hue: clip.hue, saturation: 0.55, brightness: 0.75),
                                SwiftUI.Color(hue: clip.hue, saturation: 0.75, brightness: 0.45)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    .onReorder { _ in /* persist order here */ }
    .frame(height: 340)
    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container))
    .cardSurface()
    .padding(Tokens.Space.xl)
    .frame(width: 420)
}

#Preview("Placeholder thumbnails, no selection") {
    @Previewable @State var clips = Array(demoClips.prefix(3))
    PlaylistIterator(items: $clips, name: { $0.name })
        .showsIndex(false)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container))
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 380)
}

#Preview("Empty state, dark") {
    @Previewable @State var clips: [DemoClip] = []
    PlaylistIterator(items: $clips, name: { $0.name })
        .emptyMessage("No clips yet — add media to this playlist.")
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container))
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 380)
        .preferredColorScheme(.dark)
}

#endif
