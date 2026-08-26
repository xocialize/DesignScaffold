import DesignScaffold
import SwiftUI

/// An in or out bracket: a full-height rule with a foot pointing into the marked span, so
/// the two are distinguishable at a glance without a label.
struct TimelineBracket: View {
    let isIn: Bool
    let theme: TimelineTheme

    var body: some View {
        Rectangle()
            .fill(theme.selection)
            .frame(width: theme.hairline * 2)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(theme.selection)
                    .frame(width: 7, height: 7)
                    // The foot points INTO the span: right for in, left for out.
                    .offset(x: isIn ? 3 : -3)
            }
            .contentShape(Rectangle().inset(by: -6))   // grabbable without being a hairline
    }
}
