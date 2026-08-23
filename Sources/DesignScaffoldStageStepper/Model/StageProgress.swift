import Foundation

/// How a node stands relative to the live one.
public enum StageState: Equatable, Sendable {
    case complete
    case current
    case upcoming
}

/// Everything a ``StageStepper`` displays: the plan (set once, before the run) and the
/// live position within it. The projections are pure so the display rules are
/// unit-tested rather than eyeballed.
///
/// ```swift
/// StageProgress(
///     nodes: plan,
///     currentIndex: 1,
///     counterText: "step 5 of 8 · pass 1 of 2",
///     elapsedInNode: 42)
/// ```
///
/// **Counters are text, never a bar.** Phases are wildly unequal in time — 48 fast ticks
/// can pass in one slow tick — so a percentage synthesised across phases races and then
/// appears frozen. This type deliberately exposes no overall fraction; liveness comes
/// from the pulse, the counter text, and the elapsed timer.
public struct StageProgress: Equatable, Sendable {

    /// The ordered plan. Known up front so the connecting line is complete on first paint.
    public var nodes: [StageNode]

    /// Index of the live node; `nil` before the run starts (nothing lit yet).
    ///
    /// Pass `nodes.count` to mean **the whole run is complete** — every node reads as
    /// done and no node is live. Hosts should advance this monotonically: events can
    /// arrive out of order or repeat, and a stepper that walks backwards reads as a bug.
    public var currentIndex: Int?

    /// Pre-formatted counters for the live node ("step 5 of 8 · pass 1 of 2"). The host
    /// formats these — a genuinely unknown total must never render as zero.
    public var counterText: String?

    /// Seconds the live node has been running; drives the liveness affordance.
    public var elapsedInNode: TimeInterval

    public init(
        nodes: [StageNode],
        currentIndex: Int? = nil,
        counterText: String? = nil,
        elapsedInNode: TimeInterval = 0
    ) {
        self.nodes = nodes
        self.currentIndex = currentIndex
        self.counterText = counterText
        self.elapsedInNode = elapsedInNode
    }

    // MARK: - Display projections (pure, unit-tested)

    /// How the node at `index` should render.
    public func state(at index: Int) -> StageState {
        guard let currentIndex else { return .upcoming }
        if index < currentIndex { return .complete }
        if index == currentIndex { return .current }
        return .upcoming
    }

    /// The live node, or `nil` before the run starts and after it completes
    /// (`currentIndex == nodes.count` is deliberately out of bounds).
    public var currentNode: StageNode? {
        guard let currentIndex, nodes.indices.contains(currentIndex) else { return nil }
        return nodes[currentIndex]
    }

    /// True once every node is complete.
    public var isComplete: Bool {
        !nodes.isEmpty && currentIndex == nodes.count
    }

    /// Whether the "still working" affordance (elapsed timer + any `slowHint`) is due:
    /// a node is live and has been running longer than `delay`. Suppressed on quick
    /// nodes so the stepper stays quiet when nothing is wrong.
    public func showsLiveness(after delay: TimeInterval) -> Bool {
        currentNode != nil && elapsedInNode > delay
    }

    /// VoiceOver phrasing for one node — position, title, state, and (when live) the
    /// counters, so the stepper is legible without seeing the dots.
    public func accessibilityLabel(at index: Int) -> String {
        guard nodes.indices.contains(index) else { return "" }
        var parts = ["Step \(index + 1) of \(nodes.count)", nodes[index].title]
        switch state(at: index) {
        case .complete: parts.append("complete")
        case .current:
            parts.append("in progress")
            if let counterText { parts.append(counterText) }
        case .upcoming: parts.append("not started")
        }
        return parts.joined(separator: ", ")
    }
}
