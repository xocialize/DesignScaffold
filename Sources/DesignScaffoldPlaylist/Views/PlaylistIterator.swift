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

    // Added in 0.21.0 (AB-A-0045). Every one defaults to "absent", so a 0.20.0 call site
    // compiles unchanged and renders identically — the row only changes shape when a host
    // asks it to.
    var rowState: (Item) -> PlaylistRowState = { _ in .normal }
    var onActivate: ((Item) -> Void)?
    var rowContextMenu: ((Item) -> AnyView)?
    var rowActions: ((Item) -> [PlaylistRowAction])?
    var rowActionPlacement: PlaylistRowActionPlacement = .trailing
    var rowAccessory: ((Item) -> AnyView)?

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
        let state = rowState(item)
        return HStack(spacing: theme.contentSpacing) {
            // ⚠️ Gestures, drag and the combined accessibility element live on the CONTENT
            // region, not the row. Before the trailing column existed the whole row was one
            // hit target and one VoiceOver element; a button placed inside that would have
            // fought the drag, toggled the selection on its way to being pressed, and been
            // swallowed by `children: .combine` so a screen reader never found it.
            content(item, number: number, state: state)
                .contentShape(Rectangle())
                .modifier(RowTap(selected: selected,
                                 select: { toggleSelection(item, selected: selected) },
                                 // ⚠️ Activation SELECTS (sets, never toggles) before it
                                 // fires. `exclusively(before:)` swallows the first click of
                                 // a double-click entirely, so without this a double-click
                                 // activated a row that was never selected — measured in the
                                 // lab as ACTIVATE with no SELECT line. Finder and Mail
                                 // select-then-open, and a Take on an unselected row reads
                                 // as the app acting on something the user did not pick.
                                 activate: onActivate.map { handler in {
                                     selection?.wrappedValue = item.id
                                     handler(item)
                                 } }))
                .onDrag {
                    draggingId = item.id
                    return NSItemProvider(object: String(describing: item.id) as NSString)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityText(item, number: number, active: active,
                                                      state: state))
                .accessibilityAddTraits(selected ? .isSelected : [])
                // ⚠️ The inline strip is an OVERLAY applied after `.onDrag`, `.onTapGesture`
                // and the combined accessibility element — not a child of the content block.
                // The first cut nested the buttons inside the metadata line; a click was fine
                // (the button wins), but a press-and-move on a button became a ROW DRAG,
                // because the button sat inside the drag source. Measured in the lab:
                // `INLINE-REORDER [2, 3, 1, 4, 5]` from dragging a toggle. Layering the strip
                // above the block puts it outside the drag source, the select gesture and
                // the combined element by construction — exactly where the trailing column
                // already lives, just aligned to line two.
                .overlay(alignment: Alignment(horizontal: .trailing, vertical: .inlineStrip)) {
                    inlineStrip(item)
                }
            trailingColumn(item)
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
        .modifier(OptionalHelp(text: state.reason))
        .modifier(OptionalContextMenu(menu: rowContextMenu.map { menu in { menu(item) } }))
        .accessibilityElement(children: .contain)
    }

    private func content(_ item: Item, number: Int, state: PlaylistRowState) -> some View {
        HStack(spacing: theme.contentSpacing) {
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
                    .foregroundStyle(state.isDimmed ? theme.dimmedText : theme.nameText)
                    .strikethrough(state.isStruck)
                    .lineLimit(1)
                metadataLine(item, dimmed: state.isDimmed)
                    // Inline placement: reserve the strip's width on line two so the times
                    // never run under the icons, and publish this line's centre as the
                    // guide the overlay aligns to. Zero and a no-op for `.trailing`.
                    .padding(.trailing, inlineStripWidth(item))
                    .alignmentGuide(.inlineStrip) { $0[VerticalAlignment.center] }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Inline strip

    private func inlineActions(_ item: Item) -> [PlaylistRowAction] {
        rowActionPlacement == .inline ? (rowActions?(item) ?? []) : []
    }

    /// What the strip will occupy, so line two can make room for it. Each button's width is
    /// floored the same way ``PlaylistActionButton`` floors it.
    private func inlineStripWidth(_ item: Item) -> CGFloat {
        let n = inlineActions(item).count
        guard n > 0 else { return 0 }
        let button = max(theme.actionSize, Tokens.Layout.minimumHitTarget)
        return CGFloat(n) * button + CGFloat(n - 1) * theme.actionSpacing + Tokens.Space.s
    }

    @ViewBuilder
    private func inlineStrip(_ item: Item) -> some View {
        let actions = inlineActions(item)
        if !actions.isEmpty {
            HStack(spacing: theme.actionSpacing) {
                ForEach(actions) { PlaylistActionButton($0).theme(theme) }
            }
        }
    }

    /// The trailing column: declared actions first, then the escape-hatch accessory.
    /// Renders nothing — and takes no space — when a host has asked for neither.
    @ViewBuilder
    private func trailingColumn(_ item: Item) -> some View {
        // Inline actions live on the metadata line; the accessory is a column thing always.
        let actions = rowActionPlacement == .trailing ? (rowActions?(item) ?? []) : []
        if !actions.isEmpty || rowAccessory != nil {
            HStack(spacing: theme.actionSpacing) {
                ForEach(actions) { PlaylistActionButton($0).theme(theme) }
                if let rowAccessory { rowAccessory(item) }
            }
        }
    }

    private func toggleSelection(_ item: Item, selected: Bool) {
        guard let selection else { return }
        selection.wrappedValue = selected ? nil : item.id
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
    private func metadataLine(_ item: Item, dimmed: Bool) -> some View {
        let metadata = metadata(item)
        if !metadata.isEmpty {
            HStack(spacing: Tokens.Space.s) {
                ForEach(metadata, id: \.self) { metadatum in
                    HStack(spacing: Tokens.Space.xs) {
                        Text(metadatum.label)
                            .font(theme.metadataLabelFont)
                            .foregroundStyle(dimmed ? theme.dimmedText : theme.secondaryText)
                        Text(metadatum.value)
                            .font(theme.metadataValueFont).monospacedDigit()
                            .foregroundStyle(dimmed ? theme.dimmedText : theme.metadataValueText)
                    }
                }
            }
            .lineLimit(1)
        }
    }

    private func accessibilityText(_ item: Item, number: Int, active: Bool,
                                   state: PlaylistRowState) -> String {
        var parts = ["\(number). \(name(item))"]
        parts += metadata(item).map { "\($0.label) \($0.value)" }
        if active { parts.append("current item") }
        // Spoken, not just greyed: VoiceOver hears WHY the row will be skipped.
        if let prefix = state.accessibilityPrefix { parts.append(prefix) }
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

    // MARK: Row state · interaction · trailing column (0.21.0, AB-A-0045)

    /// What the player will do with each row. See ``PlaylistRowState`` — the component
    /// renders the treatment, the host defines the meaning, and rows stay draggable.
    func rowState(_ state: @escaping (Item) -> PlaylistRowState) -> PlaylistIterator {
        var copy = self
        copy.rowState = state
        return copy
    }

    /// Double-click (or double-tap) on a row.
    ///
    /// ⚠️ Setting this changes what a double-click does to selection, and it has to. The
    /// row's single tap TOGGLES selection, so without this a double-click selected the row
    /// and then cleared it. With it, a double-click SELECTS the row (sets, never toggles) and
    /// then activates it — the Finder/Mail convention — so a host binding this to Take or
    /// Open acts on the row the user just picked. Unset, the row behaves exactly as it did
    /// in 0.20.0, with no double-tap wait on the single tap.
    func onActivate(_ handler: @escaping (Item) -> Void) -> PlaylistIterator {
        var copy = self
        copy.onActivate = handler
        return copy
    }

    /// A context menu for the whole row — right-click or long-press anywhere on it.
    func rowContextMenu<Menu: View>(@ViewBuilder _ menu: @escaping (Item) -> Menu) -> PlaylistIterator {
        var copy = self
        copy.rowContextMenu = { AnyView(menu($0)) }
        return copy
    }

    /// Icon buttons the component draws. See ``PlaylistRowAction`` for why this is
    /// declarative, ``PlaylistActionButton`` for what is drawn, and
    /// ``PlaylistRowActionPlacement`` for where.
    ///
    /// `.trailing` (the default, and 0.21.0's only behaviour) is a full-height column beside
    /// the whole content block. `.inline` puts the buttons on the metadata line, so the name
    /// keeps the full row width — MarqueeStudio measured the difference at ~292pt for the
    /// name against ~184pt (AB-A-0058).
    func rowActions(_ actions: @escaping (Item) -> [PlaylistRowAction],
                    placement: PlaylistRowActionPlacement = .trailing) -> PlaylistIterator {
        var copy = self
        copy.rowActions = actions
        copy.rowActionPlacement = placement
        return copy
    }

    /// The escape hatch: arbitrary content after the declared actions, in the same column and
    /// outside the row's drag and select gestures. Compose ``PlaylistActionButton`` inside it
    /// if what you want is a button that does not fit ``PlaylistRowAction``'s three shapes.
    func rowAccessory<Accessory: View>(@ViewBuilder _ accessory: @escaping (Item) -> Accessory) -> PlaylistIterator {
        var copy = self
        copy.rowAccessory = { AnyView(accessory($0)) }
        return copy
    }

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


// MARK: - Row modifiers

/// Single tap toggles selection; a double tap, when a host wants one, is claimed as
/// `activate` and does NOT also toggle.
///
/// The branch is on whether `activate` was supplied — fixed at construction, never state — so
/// it cannot change shape mid-gesture, which is the way a `@ViewBuilder` `if` normally kills a
/// drag (AB-L-0061). The unset branch is byte-for-byte the 0.20.0 behaviour: a plain
/// `onTapGesture` with no double-tap wait.
private struct RowTap: ViewModifier {
    let selected: Bool
    let select: () -> Void
    let activate: (() -> Void)?

    func body(content: Content) -> some View {
        if let activate {
            content.gesture(
                TapGesture(count: 2).onEnded { activate() }
                    .exclusively(before: TapGesture(count: 1).onEnded { select() })
            )
        } else {
            content.onTapGesture { select() }
        }
    }
}

/// `.help` only when there is something to say. Applying `.help("")` to every row is the
/// empty-tooltip habit the migration contract calls out.
private struct OptionalHelp: ViewModifier {
    let text: String?
    func body(content: Content) -> some View {
        if let text { content.help(text) } else { content }
    }
}

/// `.contextMenu` only when a host supplied one; an empty menu still installs a menu.
private struct OptionalContextMenu: ViewModifier {
    let menu: (() -> AnyView)?
    func body(content: Content) -> some View {
        if let menu { content.contextMenu { menu() } } else { content }
    }
}


// MARK: - Placement

/// Where ``PlaylistIterator/rowActions(_:placement:)`` draws its buttons.
public enum PlaylistRowActionPlacement: Sendable {
    /// A full-height column beside the content block. The 0.21.0 behaviour, and the default.
    case trailing
    /// On the metadata line, trailing. The name keeps the full row width; the times and the
    /// icons share line two. Mitti's cue rows do this, and MarqueeStudio measured it as the
    /// only placement that stops the name truncating on a 420pt rail (AB-A-0058).
    ///
    /// The escape-hatch accessory is unaffected — it is a column thing regardless.
    case inline
}

/// The vertical guide the inline strip aligns to: the centre of the metadata line.
///
/// Set on line two inside `content` and read by the overlay in `row`. A custom guide set on a
/// descendant propagates up through the stacks, which is what lets a view layered OVER the
/// whole content block line up with one line inside it. When a row has no metadata, nothing
/// sets the guide and it falls back to the block's centre — the strip is simply centred.
extension VerticalAlignment {
    private enum InlineStripID: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat { d[VerticalAlignment.center] }
    }
    static let inlineStrip = VerticalAlignment(InlineStripID.self)
}
