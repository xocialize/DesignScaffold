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

    /// Which way the pointer is travelling. Snapping never moves a clip against the drag:
    /// being yanked backwards while dragging forwards is what makes snapping feel like it is
    /// fighting you rather than helping.
    public enum Direction: Equatable, Sendable {
        case forward, backward, any

        public init(translation: Double) {
            self = translation > 0 ? .forward : translation < 0 ? .backward : .any
        }
    }

    /// A chosen snap: where the clip lands, and which candidate did it.
    public struct Result: Equatable, Sendable {
        public let start: TimeInterval
        public let candidate: TimeInterval
    }

    /// The adjusted start for a dragged clip.
    ///
    /// **Both edges compete**: a clip snaps when *either* its head or its tail comes near a
    /// candidate, and the closer edge wins. Snapping only the head would leave a clip's
    /// tail visibly short of the next clip's head — the case an editor cares most about.
    ///
    /// - Parameters:
    ///   - direction: rejects any snap that would move the clip against the drag.
    ///   - held: the candidate this drag is currently snapped to, if any. While it stays in
    ///     range it wins, which is what stops the clip lurching between two targets.
    /// - Returns: where the clip lands and which candidate caught it, or `nil` for no snap.
    public static func snap(
        start: TimeInterval, duration: TimeInterval,
        candidates: [TimeInterval], tolerance: TimeInterval,
        direction: Direction = .any,
        held: TimeInterval? = nil
    ) -> Result? {
        guard tolerance > 0 else { return nil }

        // Every way this clip could land: head onto a candidate, or tail onto one.
        var options: [Result] = []
        for candidate in candidates {
            if abs(candidate - start) <= tolerance {
                options.append(Result(start: candidate, candidate: candidate))
            }
            let tail = start + duration
            if abs(candidate - tail) <= tolerance {
                options.append(Result(start: candidate - duration, candidate: candidate))
            }
        }

        // Never pull the clip back against the direction of travel.
        switch direction {
        case .forward: options = options.filter { $0.start >= start }
        case .backward: options = options.filter { $0.start <= start }
        case .any: break
        }
        guard !options.isEmpty else { return nil }

        // Hysteresis: keep the candidate already holding this drag while it remains in
        // range. Without it, head and tail trade the win as the clip moves and it jumps
        // between two unrelated positions — the chop this is here to remove.
        if let held, let staying = options.first(where: { $0.candidate == held }) {
            return staying
        }
        return options.min { abs($0.start - start) < abs($1.start - start) }
    }

    /// Direction-free convenience — the whole candidate set, closest edge wins.
    public static func snapStart(
        start: TimeInterval, duration: TimeInterval,
        candidates: [TimeInterval], tolerance: TimeInterval
    ) -> TimeInterval? {
        snap(start: start, duration: duration,
             candidates: candidates, tolerance: tolerance)?.start
    }

    /// Collect candidates from every source across the visible range.
    public static func candidates(
        from sources: [TimelineSnapSource], in range: ClosedRange<TimeInterval>
    ) -> [TimeInterval] {
        sources.flatMap { $0.candidates(range) }
    }
}
