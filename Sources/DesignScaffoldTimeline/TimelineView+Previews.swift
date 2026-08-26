//  TimelineView+Previews.swift
//  Canvas gallery. No theme calls: the scaffold look IS the default.

import DesignScaffold
import SwiftUI

private struct DemoClip: TimelineClip {
    let id: Int
    let start: TimeInterval
    let duration: TimeInterval
    let trackIndex: Int
    var title: String
    var hue: Double
}

private let demoTracks = [
    TimelineTrack(id: "v1", name: "V1", kind: .video, controls: [.lock, .enable]),
    TimelineTrack(id: "a1", name: "A1", kind: .audio, controls: [.mute, .solo, .lock]),
    TimelineTrack(id: "subs", name: "Subs", kind: .subtitle, controls: [.enable]),
]

private let demoClips = [
    DemoClip(id: 1, start: 0, duration: 4.5, trackIndex: 0, title: "harbour", hue: 0.55),
    DemoClip(id: 2, start: 4.5, duration: 3.2, trackIndex: 0, title: "harbour · take 2", hue: 0.58),
    DemoClip(id: 3, start: 8.6, duration: 5.0, trackIndex: 0, title: "portrait", hue: 0.78),
    DemoClip(id: 4, start: 0.4, duration: 7.0, trackIndex: 1, title: "roxy · voice", hue: 0.33),
    DemoClip(id: 5, start: 1.2, duration: 3.0, trackIndex: 2, title: "…only two meetings", hue: 0.12),
]

private struct DemoBody: View {
    let clip: DemoClip
    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(colors: [SwiftUI.Color(hue: clip.hue, saturation: 0.5, brightness: 0.62),
                                    SwiftUI.Color(hue: clip.hue, saturation: 0.7, brightness: 0.40)],
                           startPoint: .top, endPoint: .bottom)
            Text(clip.title).font(Tokens.Font.caption).foregroundStyle(.white)
                .padding(.horizontal, Tokens.Space.xs).lineLimit(1)
        }
    }
}

#Preview("T1 — the anatomy") {
    @Previewable @State var geometry = TimelineGeometry(pointsPerSecond: 60)
    @Previewable @State var playhead: TimeInterval = 4.5
    @Previewable @State var selection: Set<Int> = [2]
    TimelineView(tracks: demoTracks, clips: demoClips,
                 geometry: $geometry, playhead: $playhead, selection: $selection) {
        DemoBody(clip: $0)
    }
    .frame(width: 900, height: 220)
    .padding(Tokens.Space.xl)
}

#Preview("Zoomed out — ticks step up") {
    @Previewable @State var geometry = TimelineGeometry(pointsPerSecond: 12)
    @Previewable @State var playhead: TimeInterval = 4.5
    @Previewable @State var selection: Set<Int> = []
    TimelineView(tracks: demoTracks, clips: demoClips,
                 geometry: $geometry, playhead: $playhead, selection: $selection) {
        DemoBody(clip: $0)
    }
    .frame(width: 900, height: 220)
    .padding(Tokens.Space.xl)
}

#Preview("Empty timeline, dark") {
    @Previewable @State var geometry = TimelineGeometry()
    @Previewable @State var playhead: TimeInterval = 0
    @Previewable @State var selection: Set<Int> = []
    TimelineView(tracks: demoTracks, clips: [DemoClip](),
                 geometry: $geometry, playhead: $playhead, selection: $selection) {
        DemoBody(clip: $0)
    }
    .frame(width: 900, height: 220)
    .padding(Tokens.Space.xl)
    .preferredColorScheme(.dark)
}
