//
//  ⚠️ macOS-only. This target is wrapped in `#if os(macOS)` because it is built on AppKit
//  API with no iOS equivalent — see `Docs/PLATFORMS.md`. On iOS the module compiles to
//  nothing, so an app that adds this product by mistake gets "cannot find X in scope"
//  rather than a wall of AppKit errors, and the package as a whole still builds.
//
#if os(macOS)

import CoreGraphics
import Foundation

/// Which edge of a clip an edge-drag is trimming.
public enum TimelineEdge: Equatable, Sendable {
    case leading, trailing
}

/// The pure arithmetic behind moving and trimming a clip. Extracted so the rules are
/// unit-tested rather than emergent from gesture code — the same reason
/// `PlaylistReorder.liveMove` lives outside its view.
///
/// None of it mutates anything: gestures compute a result and hand it to the host, which
/// owns the document.
public enum TimelineEdit {

    /// Where a dragged clip lands.
    ///
    /// - Parameters:
    ///   - deltaTime: horizontal drag translated to seconds through the geometry.
    ///   - deltaTracks: vertical drag resolved to a signed row count.
    ///   - trackCount: rows available; the result is clamped inside them.
    /// - Returns: the new start (never negative) and track index.
    public static func move(
        start: TimeInterval, trackIndex: Int,
        deltaTime: TimeInterval, deltaTracks: Int, trackCount: Int
    ) -> (start: TimeInterval, trackIndex: Int) {
        let newStart = max(0, start + deltaTime)
        guard trackCount > 0 else { return (newStart, trackIndex) }
        let newTrack = min(max(0, trackIndex + deltaTracks), trackCount - 1)
        return (newStart, newTrack)
    }

    /// Where a trimmed edge lands.
    ///
    /// Trimming the LEADING edge moves the start and changes the duration inversely — the
    /// clip's tail stays put, which is what makes a trim read as a trim rather than a move.
    /// Both edges respect `minimumDuration`, and a leading trim additionally cannot push
    /// the start below zero.
    public static func trim(
        start: TimeInterval, duration: TimeInterval,
        edge: TimelineEdge, deltaTime: TimeInterval,
        minimumDuration: TimeInterval
    ) -> (start: TimeInterval, duration: TimeInterval) {
        let floor = max(minimumDuration, 0)
        switch edge {
        case .leading:
            let end = start + duration
            let newStart = min(max(0, start + deltaTime), end - floor)
            return (newStart, end - newStart)
        case .trailing:
            return (start, max(floor, duration + deltaTime))
        }
    }

    /// Resolve a vertical drag to a signed row count, walking real row heights rather than
    /// assuming they are uniform — a video row is 64 and a subtitle row 28, so a fixed
    /// divisor would drift as the drag crosses rows of different kinds.
    public static func trackDelta(
        from trackIndex: Int, verticalTranslation: CGFloat, heights: [CGFloat]
    ) -> Int {
        guard heights.indices.contains(trackIndex) else { return 0 }
        var remaining = verticalTranslation
        var index = trackIndex
        if remaining > 0 {
            while index + 1 < heights.count {
                let step = (heights[index] + heights[index + 1]) / 2
                if remaining < step { break }
                remaining -= step
                index += 1
            }
        } else {
            while index - 1 >= 0 {
                let step = (heights[index] + heights[index - 1]) / 2
                if -remaining < step { break }
                remaining += step
                index -= 1
            }
        }
        return index - trackIndex
    }
}

#endif
