import DesignScaffold
import SwiftUI

/// A row of capsule filter chips, single-select, wrapping when the row runs out of width.
///
/// ```swift
/// enum Kind: String, CaseIterable, Identifiable {
///     case all, video, image, audio
///     var id: Self { self }
/// }
/// @State private var kind: Kind.ID = .all
///
/// ChipRow(Kind.allCases, selection: $kind) { $0.rawValue.capitalized }
/// ```
///
/// **Single-select, and deliberately not more.** Both observed uses have an "All" chip and
/// neither has ever wanted multi-select, so the selection is a plain `Binding<Item.ID>` —
/// exactly one chip is always active. A multi-select variant would be a different component
/// with a different affordance, not a flag on this one; adding it speculatively would mean
/// inventing an interaction nobody has asked for.
public struct ChipRow<Item: Identifiable, Label: StringProtocol>: View {

    let items: [Item]
    @Binding var selection: Item.ID
    let label: (Item) -> Label
    var themeOverride: ChipRowTheme?

    var theme: ChipRowTheme { themeOverride ?? .scaffold }

    public init(_ items: [Item], selection: Binding<Item.ID>,
                label: @escaping (Item) -> Label) {
        self.items = items
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        ChipFlowLayout(spacing: theme.spacing) {
            ForEach(items) { item in
                chip(item)
            }
        }
    }

    private func chip(_ item: Item) -> some View {
        let isSelected = item.id == selection
        return Button { selection = item.id } label: {
            Text(label(item))
                .font(theme.font)
                .foregroundStyle(isSelected ? theme.selectedText : theme.text)
                .padding(.vertical, theme.verticalPadding)
                .padding(.horizontal, theme.horizontalPadding)
                .background(isSelected ? theme.selectedFill : Color.clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(label(item))))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

public extension ChipRow {
    /// Override the visual theme. Without this, ``ChipRowTheme/scaffold`` is used.
    func theme(_ theme: ChipRowTheme) -> ChipRow {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}

/// Lays chips left to right, wrapping to a new row when the width runs out.
///
/// A real `Layout` rather than a `ScrollView` of an `HStack`: a filter row that scrolls
/// hides its own options, and one that clips silently loses them. The packing itself is
/// `ChipFlow`, which is unit-tested.
struct ChipFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let sizes: [CGSize] = subviews.map { $0.sizeThatFits(.unspecified) }
        let widths: [CGFloat] = sizes.map(\.width)
        let rows = ChipFlow.rows(widths: widths, maxWidth: maxWidth, spacing: spacing)
        let chipHeight: CGFloat = sizes.map(\.height).max() ?? 0
        // Hoisted into statements: as one expression this defeats the type-checker.
        var widest: CGFloat = 0
        for row in rows {
            var rowWidth: CGFloat = 0
            for index in row { rowWidth += widths[index] }
            rowWidth += CGFloat(max(0, row.count - 1)) * spacing
            widest = max(widest, rowWidth)
        }
        let height = ChipFlow.height(rowCount: rows.count, chipHeight: chipHeight,
                                     spacing: spacing)
        return CGSize(width: min(widest, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        let sizes: [CGSize] = subviews.map { $0.sizeThatFits(.unspecified) }
        let widths: [CGFloat] = sizes.map(\.width)
        let rows = ChipFlow.rows(widths: widths, maxWidth: bounds.width, spacing: spacing)
        let chipHeight: CGFloat = sizes.map(\.height).max() ?? 0
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row {
                subviews[index].place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                                      proposal: ProposedViewSize(sizes[index]))
                x += sizes[index].width + spacing
            }
            y += chipHeight + spacing
        }
    }
}
