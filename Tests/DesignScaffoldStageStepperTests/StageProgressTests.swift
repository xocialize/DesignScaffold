import XCTest
@testable import DesignScaffoldStageStepper

final class StageProgressTests: XCTestCase {

    private let plan = [
        StageNode(id: "prompt", title: "Read prompt", detail: "Encoding the prompt"),
        StageNode(id: "generate", title: "Generate", detail: "Denoising"),
        StageNode(id: "decode", title: "Render frames", detail: "Decoding frames",
                  slowHint: "this step often takes the longest"),
        StageNode(id: "finish", title: "Finish", detail: "Writing the file"),
    ]

    private func progress(_ index: Int?, elapsed: TimeInterval = 0,
                          counter: String? = nil) -> StageProgress {
        StageProgress(nodes: plan, currentIndex: index,
                      counterText: counter, elapsedInNode: elapsed)
    }

    func testBeforeTheRunEveryNodeIsUpcoming() {
        let p = progress(nil)
        XCTAssertEqual(plan.indices.map(p.state(at:)), [.upcoming, .upcoming, .upcoming, .upcoming])
        XCTAssertNil(p.currentNode)
        XCTAssertFalse(p.isComplete)
    }

    func testMidRunSplitsCompleteCurrentUpcoming() {
        let p = progress(2)
        XCTAssertEqual(plan.indices.map(p.state(at:)), [.complete, .complete, .current, .upcoming])
        XCTAssertEqual(p.currentNode?.id, "decode")
        XCTAssertFalse(p.isComplete)
    }

    /// `currentIndex == nodes.count` is the deliberate "everything done" sentinel: every
    /// node reads complete and nothing is live. Hosts rely on it for terminal states.
    func testCountSentinelCompletesEveryNodeWithNoLiveNode() {
        let p = progress(plan.count)
        XCTAssertEqual(plan.indices.map(p.state(at:)), [.complete, .complete, .complete, .complete])
        XCTAssertNil(p.currentNode)
        XCTAssertTrue(p.isComplete)
    }

    func testOutOfRangeIndexDoesNotCrashOrLight() {
        let p = progress(99)
        XCTAssertNil(p.currentNode)
        XCTAssertEqual(p.state(at: 0), .complete)
    }

    func testEmptyPlanIsNotComplete() {
        let p = StageProgress(nodes: [], currentIndex: 0)
        XCTAssertFalse(p.isComplete)
        XCTAssertNil(p.currentNode)
    }

    // MARK: Liveness

    func testLivenessWaitsForTheDelay() {
        XCTAssertFalse(progress(1, elapsed: 4).showsLiveness(after: 5))
        XCTAssertFalse(progress(1, elapsed: 5).showsLiveness(after: 5))   // strictly greater
        XCTAssertTrue(progress(1, elapsed: 6).showsLiveness(after: 5))
    }

    func testLivenessNeedsALiveNode() {
        // A finished run must not keep claiming time in a step.
        XCTAssertFalse(progress(plan.count, elapsed: 600).showsLiveness(after: 5))
        XCTAssertFalse(progress(nil, elapsed: 600).showsLiveness(after: 5))
    }

    // MARK: Accessibility

    func testAccessibilityLabelsCarryPositionAndState() {
        let p = progress(1, counter: "step 5 of 8")
        XCTAssertEqual(p.accessibilityLabel(at: 0), "Step 1 of 4, Read prompt, complete")
        XCTAssertEqual(p.accessibilityLabel(at: 1), "Step 2 of 4, Generate, in progress, step 5 of 8")
        XCTAssertEqual(p.accessibilityLabel(at: 2), "Step 3 of 4, Render frames, not started")
    }

    func testAccessibilityLabelOutOfRangeIsEmpty() {
        XCTAssertEqual(progress(0).accessibilityLabel(at: 9), "")
    }
}
