import Foundation

/// One node in a run plan: a named phase the run passes through, known BEFORE the run
/// starts so the connecting line can be drawn on first paint.
///
/// Deliberately free of engine types. A host maps its own plan (LTX's `plannedStages`,
/// a download/prepare/compile lifecycle, an export pipeline) down to these, and keeps
/// its event-correlation helpers app-side.
public struct StageNode: Identifiable, Equatable, Sendable {

    /// Stable identity across the run — also the host's correlation key.
    public let id: String
    /// The short label under the dot ("Generate", "Render frames").
    public var title: String
    /// One line about the node, shown while it is live.
    public var detail: String
    /// Expectation copy for a node known to be slow AND quiet — appended to the elapsed
    /// timer ("— this step often takes the longest").
    ///
    /// Exists because the node least able to prove it is working is often the slowest
    /// one: counters go silent exactly when the wait is longest, so the honest signal is
    /// a timer plus a sentence that sets expectations.
    public var slowHint: String?

    public init(id: String, title: String, detail: String = "", slowHint: String? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
        self.slowHint = slowHint
    }
}
