//
//  PickerFilter.swift
//  DesignScaffoldPicker
//
//  The scope → search → sort pipeline, extracted so the part that decides what a user can FIND
//  is testable without a view.
//

import Foundation

public enum PickerFilter {

    /// Tag-scoped, then name-filtered, then sorted.
    ///
    /// Order matters and is not arbitrary: scoping first means the result count reflects the
    /// chips the user can see, so a search that finds nothing inside an active scope reads as
    /// "not in this tag" rather than "not in the library".
    public static func results<ID>(_ items: [PickerItem<ID>],
                                   query: String,
                                   activeTags: Set<String>,
                                   sort: PickerSort) -> [PickerItem<ID>] {
        var r = items
        if !activeTags.isEmpty {
            // ANY active tag, not ALL: chips widen a search. Requiring every tag would make a
            // second chip almost always empty the list, which reads as broken.
            r = r.filter { !$0.tags.isDisjoint(with: activeTags) }
        }
        let q = query.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            r = r.filter { $0.name.localizedCaseInsensitiveContains(q) }
        }
        switch sort {
        case .name:
            r.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .recent:
            // An item with no rank sorts last rather than first: absence of a recency is not
            // evidence of being new.
            r.sort { ($0.recencyRank ?? Int.min) > ($1.recencyRank ?? Int.min) }
        }
        return r
    }

    /// The scoping chips: every tag present, sorted.
    public static func tags<ID>(_ items: [PickerItem<ID>]) -> [String] {
        Set(items.flatMap(\.tags)).sorted()
    }

    /// Whether a Recent sort can honestly be offered.
    public static func offersRecency<ID>(_ items: [PickerItem<ID>]) -> Bool {
        items.contains { $0.recencyRank != nil }
    }
}
