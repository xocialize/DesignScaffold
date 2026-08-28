import Foundation

/// The live drag-reorder rule, kept pure so it can be unit-tested headlessly
/// (the calendar's grid-math/selection-engine pattern).
///
/// Generalised from MarqueeStudio's `EntryDropDelegate.dropEntered`: while a row is
/// dragged, entering another row's bounds moves the dragged row to that position
/// immediately, so the list reads as its final order throughout the drag. The
/// `to > from ? to + 1 : to` asymmetry is `Array.move` semantics — a downward move's
/// destination offset is *after* the target, an upward move's is *at* it.
public enum PlaylistReorder {

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

    /// Where a row ended up, expressed RELATIVE to its new neighbour.
    ///
    /// `after == nil` means it is now first among the rows shown.
    public struct Placement<ID: Hashable>: Equatable {
        public let moved: ID
        /// The row it now follows, or `nil` when it moved to the front.
        public let after: ID?

        public init(moved: ID, after: ID?) {
            self.moved = moved
            self.after = after
        }
    }

    /// Describe the move as "`moved` now follows `after`" rather than as a new absolute order.
    ///
    /// ⚠️ **This is the FILTER-SAFE report, and the reason it exists.** An absolute order is
    /// only meaningful when the list shown is the whole list. The moment a host filters — and a
    /// playlist that gains filters is the normal direction of travel, not an edge case — the
    /// visible order says nothing about where the HIDDEN rows sit, and a host applying it to
    /// its backing array would silently discard their positions.
    ///
    /// A relative placement stays true under any filter: "X now follows Y" is unambiguous
    /// whether or not rows between them are shown, and a host can resolve it against its full
    /// model by moving X to just after Y there.
    public static func placement<Item: Identifiable>(
        _ items: [Item], moved: Item.ID
    ) -> Placement<Item.ID>? {
        guard let index = items.firstIndex(where: { $0.id == moved }) else { return nil }
        return Placement(moved: moved,
                         after: index == items.startIndex ? nil : items[index - 1].id)
    }
}
