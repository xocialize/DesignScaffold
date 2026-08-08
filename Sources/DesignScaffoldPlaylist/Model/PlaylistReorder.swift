import Foundation

/// The live drag-reorder rule, kept pure so it can be unit-tested headlessly
/// (the calendar's grid-math/selection-engine pattern).
///
/// Generalised from MarqueeStudio's `EntryDropDelegate.dropEntered`: while a row is
/// dragged, entering another row's bounds moves the dragged row to that position
/// immediately, so the list reads as its final order throughout the drag. The
/// `to > from ? to + 1 : to` asymmetry is `Array.move` semantics — a downward move's
/// destination offset is *after* the target, an upward move's is *at* it.
enum PlaylistReorder {

    /// Move the row with id `dragging` to the position of the row with id `target`.
    /// No-op when either id is missing or they are the same row.
    /// - Returns: `true` when the array changed.
    @discardableResult
    static func liveMove<Item: Identifiable>(
        _ items: inout [Item], dragging: Item.ID, over target: Item.ID
    ) -> Bool {
        guard dragging != target,
              let from = items.firstIndex(where: { $0.id == dragging }),
              let to = items.firstIndex(where: { $0.id == target }) else { return false }
        items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        return true
    }
}
