import DesignScaffold
import SwiftUI

/// A run-progress stepper for a multi-phase operation: dots and a connecting line for
/// the planned nodes, a pulsing ring on the live one, and a detail line carrying the
/// node's copy, its counters, and — when a node runs long — an elapsed timer.
///
/// ```swift
/// StageStepper(progress: StageProgress(
///     nodes: plan,                       // known before the run — the line draws at once
///     currentIndex: reachedIndex,        // advance monotonically
///     counterText: "step 5 of 8",        // pre-formatted by the host
///     elapsedInNode: elapsed))
/// ```
///
/// **The stepper animates on event arrival and renders counters as text — it never
/// synthesises a percentage across phases.** Phases are unequal in time, so a
/// step-counted bar races and then looks frozen. Everything the component shows is a
/// fact the host handed it.
///
/// Engine-free by construction: the host maps its own plan to ``StageNode``s and keeps
/// its event-correlation helpers app-side.
///
/// Laid out horizontally — sized for a wide surface (a run card, a sheet). Allow roughly
/// 90pt per node so titles are not compressed.
public struct StageStepper: View {

    let progress: StageProgress
    var themeOverride: StageStepperTheme?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    /// Resolved theme — the override if set, otherwise the scaffold house style.
    var theme: StageStepperTheme { themeOverride ?? .scaffold }

    public init(progress: StageProgress) {
        self.progress = progress
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.m) {
            track
            liveDetail
        }
        .onAppear { if !reduceMotion { pulse = true } }
    }

    // MARK: Track

    private var track: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(progress.nodes.enumerated()), id: \.element.id) { index, node in
                nodeView(node, index: index)
                if index < progress.nodes.count - 1 {
                    connector(reached: progress.state(at: index) == .complete)
                }
            }
        }
    }

    private func nodeView(_ node: StageNode, index: Int) -> some View {
        let state = progress.state(at: index)
        return VStack(spacing: Tokens.Space.xs) {
            ZStack {
                Circle()
                    .fill(state == .upcoming ? theme.pending : theme.reached)
                    .frame(width: theme.dotSize, height: theme.dotSize)
                if state == .current {
                    Circle()
                        .strokeBorder(theme.reached, lineWidth: theme.ringLineWidth)
                        .frame(width: theme.currentRingSize, height: theme.currentRingSize)
                        .opacity(reduceMotion ? theme.reducedMotionRingOpacity
                                              : (pulse ? theme.pulseMinOpacity : 0.9))
                        .animation(reduceMotion ? nil
                                   : .easeInOut(duration: theme.pulseDuration)
                                       .repeatForever(autoreverses: true),
                                   value: pulse)
                }
            }
            .frame(height: theme.currentRingSize)
            Text(node.title)
                .font(state == .current ? theme.currentTitleFont : theme.titleFont)
                .foregroundStyle(titleColor(for: state))
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progress.accessibilityLabel(at: index))
    }

    private func titleColor(for state: StageState) -> Color {
        switch state {
        case .current: return theme.currentTitleText
        case .complete: return theme.completeTitleText
        case .upcoming: return theme.upcomingTitleText
        }
    }

    private func connector(reached: Bool) -> some View {
        Rectangle()
            .fill(reached ? theme.reached : theme.pending)
            .frame(height: theme.connectorHeight)
            .frame(minWidth: theme.connectorMinLength, maxWidth: .infinity)
            .padding(.horizontal, Tokens.Space.xs)
            // Centre the line on the dot row rather than the node's full height.
            .offset(y: theme.currentRingSize / 2)
            .accessibilityHidden(true)
    }

    // MARK: Live detail

    @ViewBuilder
    private var liveDetail: some View {
        if let node = progress.currentNode {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                HStack(spacing: Tokens.Space.s) {
                    if !node.detail.isEmpty {
                        Text(node.detail)
                            .font(theme.detailFont)
                            .foregroundStyle(theme.detailText)
                    }
                    if let counterText = progress.counterText {
                        Text(counterText)
                            .font(theme.counterFont)
                            .monospacedDigit()
                            .foregroundStyle(theme.counterText)
                    }
                }
                if progress.showsLiveness(after: theme.livenessDelay) {
                    Text(livenessLine(for: node))
                        .font(theme.livenessFont)
                        .foregroundStyle(theme.livenessText)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func livenessLine(for node: StageNode) -> String {
        let elapsed = Self.elapsedFormatter.string(from: progress.elapsedInNode) ?? "…"
        var line = "\(elapsed) in this step"
        if let slowHint = node.slowHint, !slowHint.isEmpty {
            line += " — \(slowHint)"
        }
        return line
    }

    private static let elapsedFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.unitsStyle = .abbreviated
        return f
    }()
}

public extension StageStepper {
    /// Override the visual theme. Without this, ``StageStepperTheme/scaffold`` is used.
    func theme(_ theme: StageStepperTheme) -> StageStepper {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}
