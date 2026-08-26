import Foundation

/// A hole between two clips on one track, handed to the consumer so it can decorate it.
///
/// ⚠️ **A gap has no durable identity.** It is the absence of clips, so its `id` is derived
/// from where it currently sits — move either neighbour and this becomes a *different* gap.
/// Do not key persistent state (a pending generation, say) to it. Anchor that to the clips on
/// either side, which do have identity, and read the gap only as geometry.
public struct TimelineGap: Identifiable, Equatable, Sendable {

    public let trackIndex: Int
    public let range: ClosedRange<TimeInterval>

    public init(trackIndex: Int, range: ClosedRange<TimeInterval>) {
        self.trackIndex = trackIndex
        self.range = range
    }

    /// Positional, not durable — see the type's note.
    public var id: String { "\(trackIndex)@\(range.lowerBound)…\(range.upperBound)" }

    public var start: TimeInterval { range.lowerBound }
    public var duration: TimeInterval { range.upperBound - range.lowerBound }
}
