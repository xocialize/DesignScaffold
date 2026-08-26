import CoreGraphics
import Foundation

/// The time ⇄ points mapping every part of a timeline reads: the ruler places its ticks
/// through it, lanes size their clips through it, the playhead positions through it, and
/// snapping converts through it. Pure, so the mapping is unit-tested rather than eyeballed
/// and every surface stays in lockstep by construction.
///
/// **Scroll sync is a consequence of this type, not a mechanism.** Ruler, headers, and
/// lanes all derive from one `visibleStart` + `pointsPerSecond`, so there are no scroll
/// offsets to keep in agreement — a nested-ScrollView design has to solve that problem
/// and this one cannot have it.
public struct TimelineGeometry: Equatable, Sendable {

    /// The zoom: how many points one second occupies.
    public var pointsPerSecond: CGFloat
    /// Time at the left edge of the lane viewport — the horizontal scroll position.
    public var visibleStart: TimeInterval
    /// Width of the lane viewport in points (excludes the track-header column).
    public var viewportWidth: CGFloat

    public init(pointsPerSecond: CGFloat = 40,
                visibleStart: TimeInterval = 0,
                viewportWidth: CGFloat = 0) {
        self.pointsPerSecond = max(pointsPerSecond, Self.minPointsPerSecond)
        self.visibleStart = visibleStart
        self.viewportWidth = viewportWidth
    }

    /// Zoom bounds: 1pt/s shows ~15 minutes across a 900pt lane; 800pt/s resolves a
    /// single frame at 24fps to 33pt.
    public static let minPointsPerSecond: CGFloat = 1
    public static let maxPointsPerSecond: CGFloat = 800

    // MARK: Time ⇄ points

    /// X position (in lane coordinates) for a time.
    public func x(for time: TimeInterval) -> CGFloat {
        CGFloat(time - visibleStart) * pointsPerSecond
    }

    /// Time at an x position in lane coordinates.
    public func time(atX x: CGFloat) -> TimeInterval {
        visibleStart + TimeInterval(x / pointsPerSecond)
    }

    /// Width for a duration.
    public func width(for duration: TimeInterval) -> CGFloat {
        CGFloat(duration) * pointsPerSecond
    }

    /// **The rule the request singled out**: a threshold expressed in POINTS converted to
    /// seconds at the current zoom, so snap feel is identical at every zoom level.
    /// A hardcoded seconds threshold drifts badly at the extremes — it is imperceptible
    /// zoomed in and grabs everything zoomed out.
    public func seconds(forPoints points: CGFloat) -> TimeInterval {
        TimeInterval(points / pointsPerSecond)
    }

    // MARK: Viewport

    /// Time at the right edge of the viewport.
    public var visibleEnd: TimeInterval {
        visibleStart + TimeInterval(viewportWidth / pointsPerSecond)
    }

    /// The time span currently on screen.
    public var visibleRange: ClosedRange<TimeInterval> {
        visibleStart...max(visibleStart, visibleEnd)
    }

    /// Whether a clip's span intersects the viewport — the virtualisation test, so long
    /// timelines render only what is on screen.
    public func isVisible(start: TimeInterval, duration: TimeInterval) -> Bool {
        start + duration >= visibleStart && start <= visibleEnd
    }

    // MARK: Mutation

    /// Zoom, clamped, keeping `anchor` (a time) pinned under the same x — the behaviour
    /// that makes pinch-to-zoom feel anchored rather than teleporting.
    public mutating func zoom(to newPointsPerSecond: CGFloat, keeping anchor: TimeInterval) {
        let anchorX = x(for: anchor)
        pointsPerSecond = min(max(newPointsPerSecond, Self.minPointsPerSecond),
                              Self.maxPointsPerSecond)
        visibleStart = anchor - TimeInterval(anchorX / pointsPerSecond)
    }

    /// Scroll so `time` sits at the viewport's leading edge, never before zero.
    public mutating func scroll(to time: TimeInterval) {
        visibleStart = max(0, time)
    }
}
