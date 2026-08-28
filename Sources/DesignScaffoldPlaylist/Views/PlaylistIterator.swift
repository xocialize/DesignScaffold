import DesignScaffold
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Metadata

/// One label · value pair rendered under a row's name (e.g. "Start 00:00:00",
/// "TRT 00:00:12", "4K", "8 s dwell").
public struct PlaylistMetadatum: Hashable, Sendable {
    public let label: String
    public let value: String

    public init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
}

// MARK: - Iterator

/// A sortable playlist list: drag-to-reorder rows of thumbnail · name · metadata,
/// with tap selection and a distinct ACTIVE (current / now-playing) marker.
///
/// Generalised from MarqueeStudio's playlist rail. The reorder works on a
/// `LazyVStack` rather than `List.onMove` so tap-to-select is kept: the list
/// reorders live as the dragged row passes over neighbours and commits once on
/// drop via ``onReorder(_:)``.
///
/// ```swift
/// PlaylistIterator(
///     items: $entries,
///     selection: $selectedEntryId,
///     active: nowPlayingId,
///     name: { $0.title },
///     metadata: { [PlaylistMetadatum("Start", $0.start), PlaylistMetadatum("TRT", $0.runtime)] }
/// ) { entry in
///     entry.artwork.resizable().scaledToFill()   // clipped to the theme's square
/// }
/// .onReorder { reordered in persist(reordered.map(\.id)) }
/// ```
///
/// The generic `Item` is the caller's own row model; the view only needs
/// `Identifiable` plus projections for the name, the metadata line, and (optionally)
/// a thumbnail view — real thumbnails are app concerns (async loads, Metal textures),
/// so they arrive as a `ViewBuilder` and are clipped to the theme's square.
///
/// Styling resolves through ``PlaylistTheme`` — the scaffold house style by default.
public struct PlaylistIterator<Item: Identifiable, Thumbnail: View>: View {

    @Binding var items: [Item]
    let selection: Binding<Item.ID?>?
    let activeId: Item.ID?
    let name: (Item) -> String
    let metadata: (Item) -> [PlaylistMetadatum]
    let thumbnail: (Item) -> Thumbnail

    var themeOverride: PlaylistTheme?
    var emptyMessage = "No items yet."
    var showsIndex = true
    var showsDragHandles = true
    var onReorder: (([Item]) -> Void)?
    var onPlace: ((PlaylistReorder.Placement<Item.ID>) -> Void)?

    @State private var draggingId: Item.ID?

    /// Resolved theme — the override if set, otherwise the scaffold house style.
    var theme: PlaylistTheme { themeOverride ?? .scaffold }

    // MARK: Initialisers

    /// - Parameters:
    ///   - items: The rows, in play order. Mutated live during a drag-reorder.
    ///   - selection: Tap-to-select binding; tapping the selected row again clears it.
    ///     Pass `nil` (the default) for a non-selectable list.
    ///   - active: The current / now-playing row, marked with the accent ring.
    ///     Display-only — advancing it is the player's job, not the list's.
    ///   - name: The row's display name.
    ///   - metadata: Label · value pairs for the row's second line (default none).
    ///   - thumbnail: The row's thumbnail content, clipped to the theme's square.
    public init(
        items: Binding<[Item]>,
        selection: Binding<Item.ID?>? = nil,
        active: Item.ID? = nil,
        name: @escaping (Item) -> String,
        metadata: @escaping (Item) -> [PlaylistMetadatum] = { _ in [] },
        @ViewBuilder thumbnail: @escaping (Item) -> Thumbnail
    ) {
        self._items = items
        self.selection = selection
        self.activeId = active
        self.name = name
        self.metadata = metadata
        self.thumbnail = thumbnail
    }

    // MARK: Body

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { offset, item in
                    row(item, number: offset + 1)
                        .onDrag {
                            draggingId = item.id
                            return NSItemProvider(object: String(describing: item.id) as NSString)
                        }
                        .onDrop(of: [.text], delegate: RowDropDelegate(
                            targetId: item.id, items: $items, draggingId: $draggingId,
                            onCommit: { onReorder?($0) },
                            onPlace: { onPlace?($0) }))
                    Divider().overlay(theme.separator)
                }
            }
        }
        .overlay {
            if items.isEmpty {
                Text(emptyMessage)
                    .font(theme.emptyFont)
                    .foregroundStyle(theme.emptyText)
            }
        }
    }

    // MARK: Row

    private func row(_ item: Item, number: Int) -> some View {
        let selected = selection?.wrappedValue == item.id
        let active = activeId == item.id
        return HStack(spacing: theme.contentSpacing) {
            if showsDragHandles {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(theme.secondaryText)
                    .help("Drag to reorder")
            }
            if showsIndex {
                Text("\(number)")
                    .font(theme.indexFont).monospacedDigit()
                    .foregroundStyle(theme.secondaryText)
                    .frame(minWidth: Tokens.Space.l, alignment: .trailing)
            }
            thumbnailWell(item)
            VStack(alignment: .leading, spacing: Tokens.Space.xs / 2) {
                Text(name(item))
                    .font(theme.nameFont)
                    .foregroundStyle(theme.nameText)
                    .lineLimit(1)
                metadataLine(item)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, theme.rowHorizontalPadding)
        .padding(.vertical, theme.rowVerticalPadding)
        .background(selected ? theme.selectionWash : SwiftUI.Color.clear)
        // The ACTIVE (current) row gets the accent ring — distinct from selection.
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .strokeBorder(active ? theme.activeRing : SwiftUI.Color.clear,
                              lineWidth: theme.activeRingWidth)
                .padding(Tokens.Space.xs / 2)
        )
        .opacity(draggingId == item.id ? 0.4 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard let selection else { return }
            selection.wrappedValue = selected ? nil : item.id
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText(item, number: number, active: active))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func thumbnailWell(_ item: Item) -> some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .fill(theme.thumbnailFill)
            .frame(width: theme.thumbnailSize, height: theme.thumbnailSize)
            .overlay(
                thumbnail(item)
                    .foregroundStyle(theme.thumbnailPlaceholder)   // placeholder inherits; real content overrides
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
    }

    @ViewBuilder
    private func metadataLine(_ item: Item) -> some View {
        let metadata = metadata(item)
        if !metadata.isEmpty {
            HStack(spacing: Tokens.Space.s) {
                ForEach(metadata, id: \.self) { metadatum in
                    HStack(spacing: Tokens.Space.xs) {
                        Text(metadatum.label)
                            .font(theme.metadataLabelFont)
                            .foregroundStyle(theme.secondaryText)
                        Text(metadatum.value)
                            .font(theme.metadataValueFont).monospacedDigit()
                            .foregroundStyle(theme.metadataValueText)
                    }
                }
            }
            .lineLimit(1)
        }
    }

    private func accessibilityText(_ item: Item, number: Int, active: Bool) -> String {
        var parts = ["\(number). \(name(item))"]
        parts += metadata(item).map { "\($0.label) \($0.value)" }
        if active { parts.append("current item") }
        return parts.joined(separator: ", ")
    }
}

// MARK: Placeholder-thumbnail convenience

/// The default thumbnail: the theme's placeholder symbol on the thumbnail well.
public struct PlaylistThumbnailPlaceholder: View {
    public var body: some View {
        Image(systemName: "photo").imageScale(.large)
    }
}

extension PlaylistIterator where Thumbnail == PlaylistThumbnailPlaceholder {
    /// A list with placeholder thumbnails — for callers with no artwork (yet).
    public init(
        items: Binding<[Item]>,
        selection: Binding<Item.ID?>? = nil,
        active: Item.ID? = nil,
        name: @escaping (Item) -> String,
        metadata: @escaping (Item) -> [PlaylistMetadatum] = { _ in [] }
    ) {
        self.init(items: items, selection: selection, active: active,
                  name: name, metadata: metadata,
                  thumbnail: { _ in PlaylistThumbnailPlaceholder() })
    }
}

// MARK: Chainable configuration (the calendar's modifier pattern)

public extension PlaylistIterator {

    /// Override the visual theme. Without this, ``PlaylistTheme/scaffold`` is used.
    func theme(_ theme: PlaylistTheme) -> PlaylistIterator {
        var copy = self
        copy.themeOverride = theme
        return copy
    }

    /// The message shown centred over an empty list.
    func emptyMessage(_ message: String) -> PlaylistIterator {
        var copy = self
        copy.emptyMessage = message
        return copy
    }

    /// Called once per completed drag-reorder with the move expressed RELATIVE to its new
    /// neighbour — "this row now follows that one", or follows nothing when it moved to the top.
    ///
    /// ⚠️ **Use this instead of ``onReorder(_:)`` whenever the list you pass in is FILTERED.**
    /// An absolute order is only true of the whole list; a relative placement survives any
    /// filter, because "X now follows Y" does not depend on what sits between them being
    /// visible. Resolve it against your full model by moving X to just after Y there.
    func onPlace(_ handler: @escaping (PlaylistReorder.Placement<Item.ID>) -> Void) -> PlaylistIterator {
        var copy = self
        copy.onPlace = handler
        return copy
    }

    /// Show or hide the 1-based position column.
    func showsIndex(_ shows: Bool = true) -> PlaylistIterator {
        var copy = self
        copy.showsIndex = shows
        return copy
    }

    /// Show or hide the drag handles. Rows stay draggable either way — the handle
    /// is an affordance, not the hit target.
    func showsDragHandles(_ shows: Bool = true) -> PlaylistIterator {
        var copy = self
        copy.showsDragHandles = shows
        return copy
    }

    /// Called once per completed drag-reorder with the full re-ordered list.
    ///
    /// ⚠️ **Only meaningful when the list shown is the WHOLE list.** If you filter the items you
    /// pass in, the visible order says nothing about where the hidden rows sit, and applying it
    /// to your backing array would discard their positions. Use ``onPlace(_:)`` there.
    func onReorder(_ handler: @escaping ([Item]) -> Void) -> PlaylistIterator {
        var copy = self
        copy.onReorder = handler
        return copy
    }
}

// MARK: - Drop delegate

/// Reorders the list live as a row is dragged over its neighbours and commits the
/// order once on drop.
@MainActor
private struct RowDropDelegate<Item: Identifiable>: DropDelegate {
    let targetId: Item.ID
    @Binding var items: [Item]
    @Binding var draggingId: Item.ID?
    let onCommit: ([Item]) -> Void
    let onPlace: (PlaylistReorder.Placement<Item.ID>) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func dropEntered(info: DropInfo) {
        guard let draggingId else { return }
        withAnimation {
            _ = PlaylistReorder.liveMove(&items, dragging: draggingId, over: targetId)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        let moved = draggingId
        draggingId = nil
        onCommit(items)
        // Reported alongside the absolute order, not instead of it: a host with an unfiltered
        // list is well served by the array, and one with a filter needs this.
        if let moved, let placement = PlaylistReorder.placement(items, moved: moved) {
            onPlace(placement)
        }
        return true
    }
}
