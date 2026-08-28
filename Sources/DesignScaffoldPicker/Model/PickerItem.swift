//
//  PickerItem.swift
//  DesignScaffoldPicker
//

import Foundation

/// One row in a ``SearchablePicker``.
public struct PickerItem<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let name: String
    /// Drives the scoping chips. Empty means this item is only reachable by search.
    public var tags: Set<String>
    /// The row's leading glyph.
    public var systemImage: String
    /// Higher is newer, supplied by the HOST.
    ///
    /// ⚠️ Explicit rather than inferred. The version this was promoted from sorted "Recent" by
    /// `id > id`, which quietly assumed an AUTOINCREMENT primary key — true for that app and
    /// false for a `UUID`, where it would have produced a confident, meaningless order. When
    /// no item carries a rank, the Recent option is not offered at all: a component should not
    /// present a sort it cannot actually perform.
    public var recencyRank: Int?

    public init(id: ID, name: String, tags: Set<String> = [],
                systemImage: String = "photo.on.rectangle", recencyRank: Int? = nil) {
        self.id = id
        self.name = name
        self.tags = tags
        self.systemImage = systemImage
        self.recencyRank = recencyRank
    }
}

public enum PickerSort: String, CaseIterable, Identifiable, Sendable {
    case name = "Name"
    case recent = "Recent"
    public var id: String { rawValue }
}
