//
//  ⚠️ macOS-only. This target is wrapped in `#if os(macOS)` because it is built on AppKit
//  API with no iOS equivalent — see `Docs/PLATFORMS.md`. On iOS the module compiles to
//  nothing, so an app that adds this product by mistake gets "cannot find X in scope"
//  rather than a wall of AppKit errors, and the package as a whole still builds.
//
#if os(macOS)

import DesignScaffold
import SwiftUI

/// The scaffold's own mark that a gap exists: a dashed outline, nothing more.
///
/// This is the whole of the scaffold's half of the agreed line — it draws *that* a gap is
/// there. Anything that means something (a generate affordance, a duration readout, a click
/// target) is the consumer's, supplied through `gapBody`.
public struct TimelineGapIndicator: View {
    let theme: TimelineTheme

    public var body: some View {
        RoundedRectangle(cornerRadius: theme.clipRadius)
            .strokeBorder(theme.separator,
                          style: StrokeStyle(lineWidth: theme.hairline, dash: [3, 3]))
            .allowsHitTesting(false)
    }
}

#endif
