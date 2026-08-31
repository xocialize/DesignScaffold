//
//  ⚠️ macOS-only. This target is wrapped in `#if os(macOS)` because it is built on AppKit
//  API with no iOS equivalent — see `Docs/PLATFORMS.md`. On iOS the module compiles to
//  nothing, so an app that adds this product by mistake gets "cannot find X in scope"
//  rather than a wall of AppKit errors, and the package as a whole still builds.
//
#if os(macOS)

import Foundation

/// Where a track has no clips.
///
/// **A gap is a hole BETWEEN clips — not the space before the first one or after the last.**
/// That is the definition the requesting consumer's own feature depends on: their generate
/// affordance fills a shot *between two frames the cut already has*, taking its anchors from
/// the clips on either side. Leading and trailing emptiness has no second anchor, so it is
/// not a gap; it is just where the timeline has not started or has ended.
///
/// The scaffold draws *that* a gap exists; the consumer decorates it (AB-A-0031).
public enum TimelineGaps {

    /// Holes between clips on one track, in time order.
    ///
    /// Overlapping and touching clips are merged first, so two clips that abut do not
    /// produce a zero-length gap and an overlap does not produce a negative one.
    public static func gaps<Clip: TimelineClip>(
        in clips: [Clip], trackIndex: Int
    ) -> [ClosedRange<TimeInterval>] {
        let spans = clips
            .filter { $0.trackIndex == trackIndex && $0.duration > 0 }
            .map { ($0.start, $0.end) }
            .sorted { $0.0 < $1.0 }
        guard spans.count > 1 else { return [] }

        var merged: [(TimeInterval, TimeInterval)] = []
        for span in spans {
            if let last = merged.last, span.0 <= last.1 {
                merged[merged.count - 1].1 = max(last.1, span.1)
            } else {
                merged.append(span)
            }
        }

        return zip(merged, merged.dropFirst()).compactMap { current, next in
            current.1 < next.0 ? current.1...next.0 : nil
        }
    }
}

/// Rubber-band selection over the lanes.
public enum TimelineMarquee {

    /// Every clip whose span intersects `times` on a track inside `tracks`.
    ///
    /// Intersection, not containment: a marquee that clips the corner of a long clip selects
    /// it. Requiring containment would make long clips unselectable by marquee at any zoom
    /// where they exceed the viewport — which is most of them.
    public static func selection<Clip: TimelineClip>(
        in clips: [Clip], times: ClosedRange<TimeInterval>, tracks: ClosedRange<Int>
    ) -> Set<Clip.ID> {
        Set(clips.lazy
            .filter { tracks.contains($0.trackIndex) }
            .filter { $0.start <= times.upperBound && $0.end >= times.lowerBound }
            .map(\.id))
    }

    /// Normalises a drag into an ordered range, so dragging up/left works like down/right.
    public static func range(from a: TimeInterval, to b: TimeInterval) -> ClosedRange<TimeInterval> {
        min(a, b)...max(a, b)
    }

    /// The same, for track indices.
    public static func range(from a: Int, to b: Int) -> ClosedRange<Int> {
        min(a, b)...max(a, b)
    }
}

#endif
