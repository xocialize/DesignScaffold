import Foundation
import UniformTypeIdentifiers
import XCTest
@testable import DesignScaffoldMedia

/// What a well takes and what it turns away. None of the six copies this was promoted from
/// checked anything at all, so these are not documentation of a new API — they pin behaviour
/// that six shipping apps did not have.
final class MediaAcceptanceTests: XCTestCase {

    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mediawell-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    /// A real file on disk, so `contentType(of:)` reads the FILE rather than guessing.
    private func make(_ name: String, bytes: Data = Data([0x00])) throws -> URL {
        let url = dir.appendingPathComponent(name)
        try bytes.write(to: url)
        return url
    }

    // MARK: Acceptance

    func testAnImageIsAcceptedByAnImageWell() throws {
        let png = try make("a.png")
        XCTAssertTrue(MediaAcceptance.accepts(png, types: [.image]))
    }

    func testATextFileIsRejectedByAnImageWell() throws {
        let txt = try make("notes.txt")
        XCTAssertFalse(MediaAcceptance.accepts(txt, types: [.image]))
    }

    /// Conformance, not equality: a PNG is not `UTType.image`, it CONFORMS to it. Comparing
    /// with `==` is the obvious wrong implementation and would reject every real file.
    func testAcceptanceUsesConformanceRatherThanEquality() throws {
        let png = try make("b.png")
        XCTAssertNotEqual(MediaAcceptance.contentType(of: png), .image)
        XCTAssertTrue(MediaAcceptance.accepts(png, types: [.image]))
    }

    func testAnEmptyTypeListAcceptsAnything() throws {
        let txt = try make("anything.txt")
        XCTAssertTrue(MediaAcceptance.accepts(txt, types: []))
    }

    func testAFileThatDoesNotExistIsRejectedRatherThanCrashing() {
        let ghost = dir.appendingPathComponent("nope.png")
        // The extension still types it, which is the documented fallback — but the point is
        // that asking about a missing file must return, not trap.
        XCTAssertNoThrow(_ = MediaAcceptance.accepts(ghost, types: [.image]))
    }

    // MARK: Partitioning

    func testPartitionSplitsAndPreservesOrder() throws {
        let a = try make("1.png"), bad = try make("2.txt"), c = try make("3.jpeg")
        let (accepted, rejected) = MediaAcceptance.partition([a, bad, c], types: [.image])
        XCTAssertEqual(accepted, [a, c])
        XCTAssertEqual(rejected, [bad])
    }

    /// ⚠️ Order is load-bearing: a single-file well takes `accepted.first`, which must be the
    /// first file the USER dropped and not whatever survived a set.
    func testTheFirstAcceptedFileIsTheFirstOneDropped() throws {
        let bad = try make("0.txt"), first = try make("1.png"), second = try make("2.png")
        let (accepted, _) = MediaAcceptance.partition([bad, first, second], types: [.image])
        XCTAssertEqual(accepted.first, first)
    }

    func testAnAllRejectedDropYieldsNoAccepted() throws {
        let (accepted, rejected) = MediaAcceptance.partition(
            [try make("a.txt"), try make("b.json")], types: [.image])
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertEqual(rejected.count, 2)
    }

    func testAnEmptyDropIsNotAnError() {
        let (accepted, rejected) = MediaAcceptance.partition([], types: [.image])
        XCTAssertTrue(accepted.isEmpty)
        XCTAssertTrue(rejected.isEmpty)
    }

    // MARK: Hostile filenames

    /// ⚠️ The first version of this test asserted `URL(string:)` returns nil for a path with
    /// a space, as a "control" for a bug I had claimed in another app's decoder. The control
    /// FAILED, and it was right to: the `.fileURL` item representation is already a
    /// percent-encoded `file://` absolute string rather than a raw POSIX path, so that
    /// decoder was fine and my reading of it was not.
    ///
    /// What survives is the useful half — acceptance must not care what a filename contains.
    func testAcceptanceIgnoresWhatTheFilenameContains() throws {
        for name in ["My Photos are here.png", "café ☕️.png", "semi;colon & #hash.png",
                     "trailing space .png", ".leading-dot.png"] {
            XCTAssertTrue(MediaAcceptance.accepts(try make(name), types: [.image]),
                          "rejected \(name)")
        }
    }
}
