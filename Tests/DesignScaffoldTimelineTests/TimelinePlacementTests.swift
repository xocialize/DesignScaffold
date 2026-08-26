import SwiftUI
import XCTest
@testable import DesignScaffoldTimeline

/// Guards the placement bug from AB-A-0031: clips must be positioned by LAYOUT, because a
/// view's hit region follows its layout frame and not its drawn position.
///
/// This measures the frame a placed view actually reports. It is the cheapest test that
/// fails if placement ever reverts to `.offset` — with `.offset`, every measured x is 0
/// no matter which time the clip sits at, which is precisely the defect: correct rendering,
/// correct edit math, and taps landing on the wrong clip.
@MainActor
final class TimelinePlacementTests: XCTestCase {

    private func measuredX(placingAt x: CGFloat) -> CGFloat {
        final class Sink: ObservableObject { var value: CGFloat = .nan }
        let sink = Sink()

        struct Probe: View {
            let x: CGFloat
            let report: (CGFloat) -> Void
            var body: some View {
                ZStack(alignment: .topLeading) {
                    Color.clear
                    Color.blue
                        .frame(width: 100, height: 40)
                        .contentShape(Rectangle())
                        .timelinePlaced(x: x, y: 4)
                        .background(GeometryReader { proxy in
                            Color.clear.onAppear { report(proxy.frame(in: .named("lane")).minX) }
                        })
                }
                .frame(width: 800, height: 60)
                .coordinateSpace(name: "lane")
            }
        }

        let host = NSHostingView(rootView: Probe(x: x, report: { sink.value = $0 }))
        host.frame = NSRect(x: 0, y: 0, width: 800, height: 60)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless],
                              backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.35))
        return sink.value
    }

    func testAPlacedClipsFrameFollowsItsTime() {
        // A clip 2 s into a 60 pt/s timeline must LAY OUT at 120pt, not merely draw there.
        XCTAssertEqual(measuredX(placingAt: 120), 120, accuracy: 0.5)
    }

    func testPlacementIsNotCollapsedToTheLaneOrigin() {
        // The signature of the .offset regression: every clip measures 0.
        let far = measuredX(placingAt: 372)
        XCTAssertEqual(far, 372, accuracy: 0.5)
        XCTAssertNotEqual(far, 0, accuracy: 0.5,
                          "placement collapsed to the lane origin — hit regions will overlap "
                          + "at x=0 and taps will land on the wrong clip (AB-A-0031)")
    }

    func testTheFirstClipStillSitsAtTheOrigin() {
        XCTAssertEqual(measuredX(placingAt: 0), 0, accuracy: 0.5)
    }
}
