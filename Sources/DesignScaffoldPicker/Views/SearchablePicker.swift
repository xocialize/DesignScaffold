//
//  SearchablePicker.swift
//  DesignScaffoldPicker
//
//  A findable selection list for large libraries.
//

import DesignScaffold
import DesignScaffoldChips
import SwiftUI

/// Search, tag scoping, sort, and optional multi-select over a list of thousands.
///
/// Pure value-driven: the host loads the items and owns what a selection DOES; the picker owns
/// finding. Rendering is lazy, so length is not the bottleneck — findability is.
///
/// ```swift
/// SearchablePicker(items) { id in open(id) }
/// ```
///
/// Multi-select, with a footer that commits the batch:
///
/// ```swift
/// SearchablePicker(items, addVerb: "Add") { ids in append(ids) }
/// ```
///
/// ## Promoted, not designed
///
/// From MarqueeStudio, where it already served three call sites. Two things changed on the way
/// in, both because "reusable" and "generic" are not the same claim:
///
/// - **Recency is host-supplied.** It used to sort Recent by `id > id`, which assumed an
///   AUTOINCREMENT key — correct there, meaningless for a `UUID`. See ``PickerItem/recencyRank``.
/// - **The tag chips are `ChipRow`.** It had grown its own horizontally SCROLLING strip, which
///   is the shape `ChipRow`'s own documentation argues against: a filter row that scrolls hides
///   its own options. `ChipRow` gained multi-select rather than a second chip implementation
///   being allowed to stand.
public struct SearchablePicker<ID: Hashable & Sendable>: View {

    private let items: [PickerItem<ID>]
    private var placeholder: String
    private var emptyMessage: String
    private var allowsTagScoping: Bool
    private var multiSelect: Bool
    private var selectedID: ID?
    private var addVerb: String
    private var onSelect: ((ID) -> Void)?
    private var onAddMany: (([ID]) -> Void)?
    var themeOverride: SearchablePickerTheme?

    @State private var query = ""
    @State private var sort: PickerSort = .name
    @State private var activeTags: Set<String> = []
    @State private var checked: Set<ID> = []

    var theme: SearchablePickerTheme { themeOverride ?? .scaffold }

    /// Single-select: a tap reports the row.
    public init(_ items: [PickerItem<ID>],
                placeholder: String = "Filter",
                emptyMessage: String = "No items.",
                allowsTagScoping: Bool = true,
                selected: ID? = nil,
                onSelect: @escaping (ID) -> Void) {
        self.items = items
        self.placeholder = placeholder
        self.emptyMessage = emptyMessage
        self.allowsTagScoping = allowsTagScoping
        self.multiSelect = false
        self.selectedID = selected
        self.addVerb = "Add"
        self.onSelect = onSelect
        self.onAddMany = nil
    }

    /// Multi-select: rows are checked, and the footer commits them together.
    public init(_ items: [PickerItem<ID>],
                placeholder: String = "Filter",
                emptyMessage: String = "No items.",
                allowsTagScoping: Bool = true,
                addVerb: String = "Add",
                onAddMany: @escaping ([ID]) -> Void) {
        self.items = items
        self.placeholder = placeholder
        self.emptyMessage = emptyMessage
        self.allowsTagScoping = allowsTagScoping
        self.multiSelect = true
        self.selectedID = nil
        self.addVerb = addVerb
        self.onSelect = nil
        self.onAddMany = onAddMany
    }

    private var tags: [String] { allowsTagScoping ? PickerFilter.tags(items) : [] }
    private var results: [PickerItem<ID>] {
        PickerFilter.results(items, query: query, activeTags: activeTags, sort: sort)
    }

    public var body: some View {
        VStack(spacing: Tokens.Space.s - 2) {
            HStack(spacing: Tokens.Space.s - 2) {
                searchField
                if PickerFilter.offersRecency(items) { sortMenu }
            }
            .padding(.horizontal, Tokens.Space.m)
            .padding(.top, Tokens.Space.s + 2)

            if !tags.isEmpty { tagChips }

            countRow
            list

            if items.isEmpty {
                Text(emptyMessage)
                    .font(theme.captionFont).foregroundStyle(theme.mutedText)
                    .padding(.bottom, Tokens.Space.s)
            }
            if multiSelect { commitButton }
        }
    }

    // MARK: Pieces

    private var countRow: some View {
        HStack {
            Text("\(results.count) item\(results.count == 1 ? "" : "s")")
                .font(theme.countFont).foregroundStyle(theme.mutedText)
            Spacer()
            if multiSelect && !checked.isEmpty {
                Button("Clear") { checked.removeAll() }
                    .buttonStyle(.plain).font(theme.countFont).foregroundStyle(theme.accent)
            }
        }
        .padding(.horizontal, Tokens.Space.m + 2)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: theme.rowSpacing) {
                ForEach(results) { row($0) }
            }
            .padding(.horizontal, Tokens.Space.s)
            .padding(.bottom, Tokens.Space.s)
        }
    }

    private var searchField: some View {
        HStack(spacing: Tokens.Space.xs + 2) {
            Image(systemName: "magnifyingglass").imageScale(.small)
                .foregroundStyle(theme.secondaryText)
            TextField(placeholder, text: $query)
                .textFieldStyle(.plain).font(theme.nameFont).foregroundStyle(theme.nameText)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").imageScale(.small)
                        .foregroundStyle(theme.mutedText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Tokens.Space.s)
        .padding(.vertical, Tokens.Space.xs + 1)
        .background(well)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(PickerSort.allCases) { option in
                Button { sort = option } label: {
                    HStack {
                        Text(option.rawValue)
                        if sort == option { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: Tokens.Space.xs) {
                Image(systemName: "arrow.up.arrow.down").imageScale(.small)
                Text(sort.rawValue).font(theme.captionFont)
            }
            .foregroundStyle(theme.secondaryText)
            .padding(.horizontal, Tokens.Space.s)
            .padding(.vertical, Tokens.Space.xs + 1)
            .background(well)
        }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
    }

    private var tagChips: some View {
        ChipRow(tags.map(TagChip.init), selection: $activeTags) { $0.id }
            .padding(.horizontal, Tokens.Space.m)
    }

    private var commitButton: some View {
        Button {
            onAddMany?(Array(checked))
            checked.removeAll()
        } label: {
            Text(checked.isEmpty ? "Select items to add" : "\(addVerb) \(checked.count)")
                .font(theme.actionFont)
                // ⚠️ `.white` ONLY on the solid accent. On the disabled fill it is the normal
                // label colour, because `.disabled()` below already dims — asking for a muted
                // colour as well dims twice and lands well under the contrast macOS's own
                // disabled buttons carry. Both halves of this were live defects.
                .foregroundStyle(checked.isEmpty ? theme.nameText : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Tokens.Space.s + 1)
                .background(RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(checked.isEmpty ? Tokens.Color.fillElevated : theme.accent))
        }
        .buttonStyle(.plain)
        .disabled(checked.isEmpty)
        .padding(.horizontal, Tokens.Space.m)
        .padding(.bottom, Tokens.Space.s + 2)
    }

    private var well: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .fill(theme.fieldFill)
            .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius)
                .strokeBorder(theme.border, lineWidth: Tokens.Layout.hairline))
    }

    @ViewBuilder
    private func row(_ item: PickerItem<ID>) -> some View {
        let isChecked = checked.contains(item.id)
        let isSelected = selectedID == item.id
        Button {
            if multiSelect {
                if isChecked { checked.remove(item.id) } else { checked.insert(item.id) }
            } else {
                onSelect?(item.id)
            }
        } label: {
            HStack(spacing: Tokens.Space.s + 1) {
                if multiSelect {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isChecked ? theme.accent : theme.mutedText)
                }
                Image(systemName: item.systemImage).imageScale(.small)
                    .foregroundStyle(theme.secondaryText)
                Text(item.name).font(theme.nameFont).foregroundStyle(theme.nameText).lineLimit(1)
                Spacer()
                if !multiSelect && isSelected {
                    Image(systemName: "checkmark").imageScale(.small)
                        .foregroundStyle(theme.accent)
                }
            }
            // The whole row, whatever the host's glyph draws.
            .contentShape(Rectangle())
            .padding(.horizontal, Tokens.Space.s + 2)
            .padding(.vertical, Tokens.Space.xs + 3)
            .background(RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill((isChecked || isSelected) ? theme.rowSelectedFill : theme.rowFill))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits((isChecked || isSelected) ? [.isButton, .isSelected] : .isButton)
    }
}

/// A tag rendered as a chip. `ChipRow` needs `Identifiable`, and a bare `String` is not.
private struct TagChip: Identifiable, Equatable {
    let id: String
    init(_ id: String) { self.id = id }
}

// MARK: - Chainable configuration

public extension SearchablePicker {
    /// Override the visual theme. Without this, ``SearchablePickerTheme/scaffold`` is used.
    func theme(_ theme: SearchablePickerTheme) -> SearchablePicker {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}
