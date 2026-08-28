//
//  WorkspaceSplit.swift
//  DesignScaffoldWorkspace
//
//  The fleet's three-panel shell: navigation rail · work area · inspector.
//

import DesignScaffold
import SwiftUI

/// A fixed three-pane workspace — a leading navigation pane, a flexible center work area, and
/// a trailing inspector, separated by hairlines.
///
/// ```swift
/// WorkspaceSplit {
///     ScreenRail(model: model)
/// } center: {
///     PreviewStage()
/// } trailing: {
///     Inspector(model: model)
/// }
/// ```
///
/// ## Why this is a component
///
/// Four apps had written it independently — MarqueeStudio twice, ML[X] Media Forge, and
/// DesignWorkspace — with four sets of widths, two different hairline idioms, and in Media
/// Forge a doc comment describing a separator the layout never drew. None of that is design
/// work; it is the same `HStack(spacing: 0)` retyped, and each copy is a fresh chance to get
/// the narrow-window behaviour wrong.
///
/// ## What it fixes that a hand-rolled HStack does not
///
/// Fixed side panes plus a `maxWidth: .infinity` center means **the center absorbs every
/// shortfall**: drag the window narrow and the work area reaches zero while both side panes
/// sit at full width. ``WorkspaceMetrics`` honours the center's minimum first and yields the
/// trailing pane, then the leading one — see its documentation for why that order.
///
/// ## Not resizable, deliberately
///
/// Every shell measured used fixed widths, so that is what this reproduces. A draggable
/// divider is a real request when someone has a real need for it — ask, rather than reaching
/// for `NavigationSplitView`, which renders an EMPTY window inside a `sizingOptions = []`
/// hosting view (measured in DesignWorkspace, where the content laid out and drew nothing).
public struct WorkspaceSplit<Leading: View, Center: View, Trailing: View>: View {

    private let leading: Leading
    private let center: Center
    private let trailing: Trailing
    private let hasTrailing: Bool
    var themeOverride: WorkspaceSplitTheme?

    var theme: WorkspaceSplitTheme { themeOverride ?? .scaffold }

    public init(@ViewBuilder leading: () -> Leading,
                @ViewBuilder center: () -> Center,
                @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
        self.hasTrailing = true
    }

    public var body: some View {
        GeometryReader { proxy in
            let widths = WorkspaceMetrics.resolve(
                available: proxy.size.width,
                leading: theme.leadingWidth,
                trailing: hasTrailing ? theme.trailingWidth : 0,
                centerMinimum: theme.centerMinimum)

            let _ = Self.log(available: proxy.size.width, widths: widths)
            HStack(spacing: 0) {
                leading
                    .frame(width: widths.leading)
                    .background(theme.paneFill)
                if theme.showsSeparators { Separator(.vertical) }
                center
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.centerFill)
                if hasTrailing {
                    if theme.showsSeparators { Separator(.vertical) }
                    trailing
                        .frame(width: widths.trailing)
                        .background(theme.paneFill)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

// MARK: - Diagnostics

extension WorkspaceSplit {
    /// Prints the width the split was offered and what it resolved to, when
    /// `DESIGNSCAFFOLD_LAYOUT_LOG` is set in the environment.
    ///
    /// It exists because "the panes are the wrong size" is answerable only with the number the
    /// component was actually GIVEN. A drawn-frame probe cannot supply it: a probe that guards
    /// on a non-zero frame — as the fleet's does — silently reports the last non-zero value for
    /// a pane that has collapsed to nothing, which is exactly the case worth seeing.
    static func log(available: CGFloat, widths: WorkspaceMetrics.Resolved) {
        guard ProcessInfo.processInfo.environment["DESIGNSCAFFOLD_LAYOUT_LOG"] != nil else { return }
        print(String(format: "WORKSPACESPLIT offered=%.0f → %.0f | %.0f | %.0f",
                     available, widths.leading, widths.center, widths.trailing))
        fflush(stdout)
    }
}

// MARK: - Two-pane

public extension WorkspaceSplit where Trailing == EmptyView {
    /// A leading pane and a work area, no inspector — DesignWorkspace's shape.
    init(@ViewBuilder leading: () -> Leading, @ViewBuilder center: () -> Center) {
        self.init(leading: leading, center: center, trailing: { EmptyView() }, hasTrailing: false)
    }
}

extension WorkspaceSplit {
    fileprivate init(@ViewBuilder leading: () -> Leading,
                     @ViewBuilder center: () -> Center,
                     @ViewBuilder trailing: () -> Trailing,
                     hasTrailing: Bool) {
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
        self.hasTrailing = hasTrailing
    }
}

// MARK: - Chainable configuration

public extension WorkspaceSplit {
    /// Override the visual theme. Without this, ``WorkspaceSplitTheme/scaffold`` is used.
    func theme(_ theme: WorkspaceSplitTheme) -> WorkspaceSplit {
        var copy = self
        copy.themeOverride = theme
        return copy
    }

    /// Pane widths, for a shell that has its own measurements.
    func paneWidths(leading: CGFloat? = nil, trailing: CGFloat? = nil,
                    centerMinimum: CGFloat? = nil) -> WorkspaceSplit {
        var copy = self
        var t = copy.theme
        if let leading { t.leadingWidth = leading }
        if let trailing { t.trailingWidth = trailing }
        if let centerMinimum { t.centerMinimum = centerMinimum }
        copy.themeOverride = t
        return copy
    }
}
