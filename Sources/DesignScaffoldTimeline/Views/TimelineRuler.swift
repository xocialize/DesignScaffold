import DesignScaffold
import SwiftUI

/// The time ruler: adaptive ticks, timecode labels, and click/drag scrub.
struct TimelineRuler: View {
    let geometry: TimelineGeometry
    let timecode: Timecode
    let theme: TimelineTheme
    /// Scrub — called continuously while dragging, so the host can move the playhead live.
    let onScrub: ((TimeInterval) -> Void)?

    var body: some View {
        let interval = TickScale.interval(pointsPerSecond: geometry.pointsPerSecond,
                                          minSpacing: theme.minTickSpacing)
        let ticks = TickScale.ticks(in: geometry.visibleRange, interval: interval)
        ZStack(alignment: .topLeading) {
            theme.rulerBackground
            ForEach(ticks, id: \.self) { tick in
                let x = geometry.x(for: tick)
                Rectangle()
                    .fill(theme.rulerTick)
                    .frame(width: theme.hairline, height: 6)
                    .offset(x: x, y: theme.rulerHeight - 6)
                Text(timecode.label(tick, interval: interval))
                    .font(theme.timecodeFont)
                    .monospacedDigit()
                    .foregroundStyle(theme.rulerLabel)
                    .fixedSize()
                    .offset(x: x + Tokens.Space.xs, y: Tokens.Space.xs / 2)
            }
        }
        .frame(height: theme.rulerHeight)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    onScrub?(max(0, geometry.time(atX: value.location.x)))
                }
        )
        .accessibilityLabel(Text("Timeline ruler"))
        .accessibilityValue(Text(timecode.exact(geometry.visibleStart)))
    }
}
