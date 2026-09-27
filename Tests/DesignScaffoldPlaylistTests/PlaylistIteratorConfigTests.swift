import SwiftUI
import XCTest
@testable import DesignScaffoldPlaylist

/// The list's configuration surface: what a chrome modifier records. The rendering
/// itself is the Component Lab's; these pin what the row code reads from.
@MainActor
final class PlaylistIteratorConfigTests: XCTestCase {

    private struct Row: Identifiable { let id: Int }

    private func list() -> PlaylistIterator<Row, EmptyView> {
        PlaylistIterator(items: .constant([Row(id: 1), Row(id: 2)]), name: { "Row \($0.id)" }) { _ in EmptyView() }
    }

    func testReorderingIsOnByDefault() {
        XCTAssertTrue(list().allowsReordering, "a 0.24.0 call site is unchanged")
        XCTAssertTrue(list().showsDragHandles)
    }

    func testAllowsReorderingOffIsRecorded() {
        XCTAssertFalse(list().allowsReordering(false).allowsReordering)
        XCTAssertTrue(list().allowsReordering(false).allowsReordering(true).allowsReordering)
    }

    func testTheOtherChromeIsUntouchedByTheSwitch() {
        let configured = list().showsIndex(false).emptyMessage("Nothing").allowsReordering(false)
        XCTAssertFalse(configured.showsIndex)
        XCTAssertEqual(configured.emptyMessage, "Nothing")
        XCTAssertFalse(configured.allowsReordering)
    }
}
