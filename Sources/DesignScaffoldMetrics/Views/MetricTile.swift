//
//  MetricTile.swift
//  DesignScaffoldMetrics
//
//  One headline measurement: a value, a unit, a label, and sometimes a caption.
//

import DesignScaffold
import SwiftUI

/// A single measurement, presented so the NUMBER is what the eye lands on.
///
/// ```swift
/// MetricTile("0.31", label: "Time to first audio", unit: "s")
/// MetricTile("2.41", label: "Resident", unit: "GB", caption: "1 of 1 resident")
/// MetricTile("−22.4", label: "Peak", unit: "dBFS", emphasis: Tokens.Color.working)
/// ```
///
/// ## Promoted from four copies, into tokens that were already waiting
///
/// Nemotron ASR, Audio8, MageVL and LLM Voice Chat each built this. The unusual part: the
/// **vocabulary for it already existed** — `Tokens.Font.metricValue`, `.metricLabel`,
/// `.metricInline`, and `Tokens.Layout.metricTileMinWidth`, whose own comment records a metric
/// grid that silently fell back to a wider layout at 132pt. The tokens were added for a
/// component nobody built, so four apps built their own against them.
///
/// The shape here is Audio8's, which was the most developed of the four and already
/// token-based — the same reason ML[X] LTX Studio's coalescing won when the probes merged.
///
/// ## Why `emphasis` is a parameter and the label colour is not
///
/// A metric's value sometimes carries a **verdict** — a clipped peak, a silent render, a
/// budget exceeded — and that belongs to the host, which is the only thing that knows what
/// good looks like. Everything else is design vocabulary and comes from tokens.
public struct MetricTile: View {

    private let value: String
    private let label: String
    private let unit: String?
    private let caption: String?
    private let emphasis: Color?
    var themeOverride: MetricTileTheme?

    var theme: MetricTileTheme { themeOverride ?? .scaffold }

    public init(_ value: String, label: String, unit: String? = nil,
                caption: String? = nil, emphasis: Color? = nil) {
        self.value = value
        self.label = label
        self.unit = unit
        self.caption = caption
        self.emphasis = emphasis
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(theme.valueFont)
                    .foregroundStyle(emphasis ?? theme.value)
                    // ⚠️ Shrink, never truncate. A clipped number is a WRONG number: "2.4…"
                    // reads as a value, and the reader has no way to know it is not one.
                    .lineLimit(1)
                    .minimumScaleFactor(theme.minimumScale)
                if let unit {
                    Text(unit).font(theme.unitFont).foregroundStyle(theme.label)
                }
            }
            Text(theme.uppercasesLabel ? label.uppercased() : label)
                .font(theme.labelFont)
                .foregroundStyle(theme.label)
            if let caption {
                Text(caption)
                    .font(theme.captionFont)
                    .foregroundStyle(theme.caption)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.padding)
        .accessibilityElement(children: .combine)
        // Read as a sentence, and the LABEL first — "time to first audio, 0.31 seconds" is a
        // fact; "0.31, time to first audio" is a quiz.
        .accessibilityLabel(Text("\(label), \(value)\(unit.map { " \($0)" } ?? "")"))
    }
}

public extension MetricTile {
    /// Override the visual theme. Without this, ``MetricTileTheme/scaffold`` is used.
    func theme(_ theme: MetricTileTheme) -> MetricTile {
        var copy = self
        copy.themeOverride = theme
        return copy
    }

    /// The carded treatment. Separate from the tile so a host can place bare tiles in its own
    /// container — which is what the inline theme is for.
    func carded() -> some View { self.cardSurface() }
}

/// A row of tiles that wraps rather than squeezing them.
///
/// ⚠️ `Tokens.Layout.metricTileMinWidth` is 140 because at 132 two tiles did NOT fit inside
/// `inspectorWidth` minus padding, and the grid silently fell back to one column — which reads
/// as a layout bug rather than as a measurement. That number is load-bearing; the comment
/// recording why has been in the token file longer than this component has existed.
public struct MetricGrid<Content: View>: View {
    private let minWidth: CGFloat
    private let spacing: CGFloat
    private let content: Content

    public init(minWidth: CGFloat = Tokens.Layout.metricTileMinWidth,
                spacing: CGFloat = Tokens.Space.s,
                @ViewBuilder content: () -> Content) {
        self.minWidth = minWidth
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth), spacing: spacing)],
                  spacing: spacing) {
            content
        }
    }
}
