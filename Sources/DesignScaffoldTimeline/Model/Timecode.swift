import Foundation

/// Timecode formatting. Two shapes, because a ruler and a playhead readout want different
/// densities: ruler labels stay compact (`00:04`, `1:02:30`), the readout is exact
/// (`00:00:04:12`).
public struct Timecode: Equatable, Sendable {

    /// Frames per second — only the frames field depends on it.
    public var frameRate: Double

    public init(frameRate: Double = 24) {
        self.frameRate = frameRate > 0 ? frameRate : 24
    }

    /// `HH:MM:SS:FF` — the exact readout. Negative times clamp to zero rather than
    /// rendering a nonsense sign in a field of fixed width.
    public func exact(_ time: TimeInterval) -> String {
        let t = max(0, time)
        let total = Int(t.rounded(.down))
        let frames = Int(((t - Double(total)) * frameRate).rounded(.down))
        return String(format: "%02d:%02d:%02d:%02d",
                      total / 3600, (total / 60) % 60, total % 60, frames)
    }

    /// Compact label for a ruler tick: `MM:SS` under an hour, `H:MM:SS` beyond it, and
    /// `SS.f` when the tick interval is sub-second (otherwise every tick reads the same).
    public func label(_ time: TimeInterval, interval: TimeInterval) -> String {
        let t = max(0, time)
        if interval < 1 {
            return String(format: "%d:%04.1f", Int(t) / 60, t.truncatingRemainder(dividingBy: 60))
        }
        let total = Int(t.rounded())
        let (h, m, s) = (total / 3600, (total / 60) % 60, total % 60)
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                     : String(format: "%02d:%02d", m, s)
    }
}
