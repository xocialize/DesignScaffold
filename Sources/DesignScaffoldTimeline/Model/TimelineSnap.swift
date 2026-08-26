import CoreGraphics
import Foundation

/// A source of times a drag can snap to. Deliberately just a closure, so a consumer
/// contributes its own candidates — markers, generated-clip boundaries, beat grid —
/// without the component knowing what any of them mean.
///
/// The closure receives the visible range so a source can answer cheaply for long
/// timelines instead of enumerating everything.
public struct TimelineSnapSource: Sendable {

    public let candidates: @Sendable (ClosedRange<TimeInterval>) -> [TimeInterval]

    public init(_ candidates: @escaping @Sendable (ClosedRange<TimeInterval>) -> [TimeInterval]) {
        self.candidates = candidates
    }

    /// Both edges of every clip, optionally excluding the one being dragged — a clip must
    /// not snap to itself.
    public static func clipEdges<C: TimelineClip>(
        _ clips: [C], excluding excludedID: C.ID? = nil
    ) -> TimelineSnapSource where C: Sendable, C.ID: Sendable {
        TimelineSnapSource { range in
            clips.lazy
                .filter { $0.id != excludedID }
                .flatMap { [$0.start, $0.end] }
                .filter { range.contains($0) }
        }
    }

    /// The playhead.
    public static func playhead(_ time: TimeInterval) -> TimelineSnapSource {
        TimelineSnapSource { range in range.contains(time) ? [time] : [] }
    }

    /// A fixed set — markers, chapter starts, a beat grid the consumer computed.
    public static func fixed(_ times: [TimeInterval]) -> TimelineSnapSource {
        TimelineSnapSource { range in times.filter { range.contains($0) } }
    }

    /// Time zero, so a clip can always be seated against the head of the timeline.
    public static let origin = TimelineSnapSource { $0.contains(0) ? [0] : [] }
}

/// Snapping, kept pure and separate from gestures.
///
/// **The tolerance is always derived from points** via
/// ``TimelineGeometry/seconds(forPoints:)`` — nothing here stores a duration, which is the
/// requirement AB-A-0031 singled out. A seconds threshold is imperceptible zoomed in and
/// grabs everything zoomed out.
public enum TimelineSnap {

    /// Nearest candidate within `tolerance`, or `nil` when nothing is close enough.
    public static func nearest(
        to time: TimeInterval, candidates: [TimeInterval], tolerance: TimeInterval
    ) -> TimeInterval? {
        guard tolerance > 0 else { return nil }
        return candidates
            .filter { abs($0 - time) <= tolerance }
            .min { abs($0 - time) < abs($1 - time) }
    }

    /// The adjusted start for a dragged clip.
    ///
    /// **Both edges compete**: a clip snaps when *either* its head or its tail comes near a
    /// candidate, and the closer edge wins. Snapping only the head would leave a clip's
    /// tail visibly short of the next clip's head — the case an editor cares most about.
    ///
    /// - Returns: the snapped start, or `nil` when neither edge is within tolerance.
    public static func snapStart(
        start: TimeInterval, duration: TimeInterval,
        candidates: [TimeInterval], tolerance: TimeInterval
    ) -> TimeInterval? {
        let head = nearest(to: start, candidates: candidates, tolerance: tolerance)
        let tail = nearest(to: start + duration, candidates: candidates, tolerance: tolerance)
        switch (head, tail) {
        case let (h?, t?):
            // Closer edge wins; a tie goes to the head, which is the edge the user is
            // conceptually placing.
            return abs(h - start) <= abs(t - (start + duration)) ? h : t - duration
        case let (h?, nil): return h
        case let (nil, t?): return t - duration
        case (nil, nil): return nil
        }
    }

    /// Collect candidates from every source across the visible range.
    public static func candidates(
        from sources: [TimelineSnapSource], in range: ClosedRange<TimeInterval>
    ) -> [TimeInterval] {
        sources.flatMap { $0.candidates(range) }
    }
}
