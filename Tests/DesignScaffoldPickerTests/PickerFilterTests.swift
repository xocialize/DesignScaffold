import XCTest
@testable import DesignScaffoldPicker

/// The pipeline decides what a user can FIND in a library of thousands. It is the part of this
/// component worth testing, and the part a screenshot cannot show.
final class PickerFilterTests: XCTestCase {

    private func item(_ id: Int, _ name: String, _ tags: Set<String> = [],
                      rank: Int? = nil) -> PickerItem<Int> {
        PickerItem(id: id, name: name, tags: tags, recencyRank: rank)
    }

    private var library: [PickerItem<Int>] {
        [item(1, "Beach loop", ["video", "promo"], rank: 1),
         item(2, "alpha card", ["image"], rank: 5),
         item(3, "Zebra stinger", ["video"], rank: 3),
         item(4, "Untagged clip")]
    }

    func testNameSortIsCaseInsensitive() {
        let r = PickerFilter.results(library, query: "", activeTags: [], sort: .name)
        XCTAssertEqual(r.map(\.name), ["alpha card", "Beach loop", "Untagged clip", "Zebra stinger"],
                       "a lowercase name must not sort after every capitalised one")
    }

    func testSearchIsCaseInsensitiveAndSubstring() {
        let r = PickerFilter.results(library, query: "EACH", activeTags: [], sort: .name)
        XCTAssertEqual(r.map(\.id), [1])
    }

    func testQueryIsTrimmed() {
        let r = PickerFilter.results(library, query: "   zebra  ", activeTags: [], sort: .name)
        XCTAssertEqual(r.map(\.id), [3], "a trailing space from a paste must not empty the list")
    }

    /// Chips WIDEN a search. Requiring every active tag would make a second chip almost always
    /// empty the list, which reads as broken rather than as a filter.
    func testMultipleTagsAreUnionNotIntersection() {
        let r = PickerFilter.results(library, query: "", activeTags: ["video", "image"], sort: .name)
        XCTAssertEqual(Set(r.map(\.id)), [1, 2, 3])
    }

    func testScopingThenSearching() {
        let r = PickerFilter.results(library, query: "a", activeTags: ["video"], sort: .name)
        XCTAssertEqual(Set(r.map(\.id)), [1, 3], "search applies WITHIN the active scope")
    }

    func testNoTagsMeansNoScoping() {
        XCTAssertEqual(PickerFilter.results(library, query: "", activeTags: [], sort: .name).count, 4)
    }

    func testRecencyUsesTheHostSuppliedRank() {
        let r = PickerFilter.results(library, query: "", activeTags: [], sort: .recent)
        XCTAssertEqual(r.map(\.id), [2, 3, 1, 4])
    }

    /// Absence of a recency is not evidence of being new.
    func testUnrankedItemsSortLastUnderRecency() {
        let r = PickerFilter.results(library, query: "", activeTags: [], sort: .recent)
        XCTAssertEqual(r.last?.id, 4)
    }

    func testRecencyIsOnlyOfferedWhenSomethingCarriesIt() {
        XCTAssertTrue(PickerFilter.offersRecency(library))
        XCTAssertFalse(PickerFilter.offersRecency([item(9, "no rank")]),
                       "a component must not offer a sort it cannot perform")
    }

    func testTagsAreTheSortedUnionAcrossItems() {
        XCTAssertEqual(PickerFilter.tags(library), ["image", "promo", "video"])
    }

    func testEmptyLibraryIsHandled() {
        let none: [PickerItem<Int>] = []
        XCTAssertTrue(PickerFilter.results(none, query: "x", activeTags: ["y"], sort: .recent).isEmpty)
        XCTAssertTrue(PickerFilter.tags(none).isEmpty)
    }

    /// A UUID key is the case the promoted version got wrong by sorting on the id itself.
    func testWorksWithANonComparableID() {
        let a = UUID(), b = UUID()
        let items = [PickerItem(id: a, name: "second", recencyRank: 1),
                     PickerItem(id: b, name: "first", recencyRank: 2)]
        XCTAssertEqual(PickerFilter.results(items, query: "", activeTags: [], sort: .recent).map(\.id),
                       [b, a])
    }
}
