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
