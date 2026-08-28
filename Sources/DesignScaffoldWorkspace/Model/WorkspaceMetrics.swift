//
//  WorkspaceMetrics.swift
//  DesignScaffoldWorkspace
//
//  Pure width arithmetic, extracted so the one thing that can silently go wrong is testable
//  without a window.
//

import CoreGraphics

/// Resolves the three pane widths for an available width.
///
/// The rule the fleet's hand-rolled shells all got wrong the same way: fixed side panes plus
/// a `maxWidth: .infinity` center means the CENTER absorbs every shortfall. Drag the window
/// narrow enough and the center reaches zero while both side panes stay at full width — the
/// work area, the reason the window exists, is the first thing to disappear.
///
/// Here the center's minimum is honoured first and the side panes yield, trailing before
/// leading: an inspector is the more disposable of the two, and collapsing the navigation rail
/// first would strand the user with content they cannot navigate away from.
public enum WorkspaceMetrics {

    public struct Resolved: Equatable, Sendable {
        public var leading: CGFloat
        public var center: CGFloat
        public var trailing: CGFloat
    }

    /// - Parameters:
    ///   - available: the width the split has to lay out in.
    ///   - leading: the requested navigation-pane width.
    ///   - trailing: the requested inspector width; 0 for a two-pane layout.
    ///   - centerMinimum: the narrowest the work area may become before the side panes yield.
    public static func resolve(available: CGFloat,
                               leading: CGFloat,
                               trailing: CGFloat,
                               centerMinimum: CGFloat) -> Resolved {
        let lead = max(0, leading), trail = max(0, trailing)
        let floor = max(0, centerMinimum)
        let width = max(0, available)

        let wanted = lead + trail + floor
        guard wanted > width else {
            return Resolved(leading: lead, center: width - lead - trail, trailing: trail)
        }

        // Short by this much. Take it from the trailing pane first, then the leading one;
        // whatever remains comes out of the center, which is all that is left to give.
        var deficit = wanted - width
        let trailCut = min(trail, deficit)
        deficit -= trailCut
        let leadCut = min(lead, deficit)
        deficit -= leadCut

        let resolvedLead = lead - leadCut
        let resolvedTrail = trail - trailCut
        return Resolved(leading: resolvedLead,
                        center: max(0, width - resolvedLead - resolvedTrail),
                        trailing: resolvedTrail)
    }
}
