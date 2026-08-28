import CoreGraphics

/// Packing chips into rows. Pure, so the wrap arithmetic is tested rather than eyeballed —
/// off-by-one wrapping is the kind of thing that looks right until one label is long.
public enum ChipFlow {

    /// Indices grouped into rows, each row no wider than `maxWidth`.
    ///
    /// A chip wider than the whole row still gets its own row rather than being dropped:
    /// clipping one long label is bad, losing it silently is worse.
    public static func rows(widths: [CGFloat], maxWidth: CGFloat, spacing: CGFloat) -> [[Int]] {
        guard !widths.isEmpty else { return [] }
        var rows: [[Int]] = []
        var current: [Int] = []
        var used: CGFloat = 0

        for (index, width) in widths.enumerated() {
            let needed = current.isEmpty ? width : used + spacing + width
            if !current.isEmpty && needed > maxWidth {
                rows.append(current)
                current = [index]
                used = width
            } else {
                current.append(index)
                used = needed
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    /// Height of a packed set: rows × chip height, plus the gaps between rows.
    public static func height(rowCount: Int, chipHeight: CGFloat, spacing: CGFloat) -> CGFloat {
        guard rowCount > 0 else { return 0 }
        return CGFloat(rowCount) * chipHeight + CGFloat(rowCount - 1) * spacing
    }
}
