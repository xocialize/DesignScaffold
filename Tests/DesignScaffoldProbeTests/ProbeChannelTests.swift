#if os(macOS)
import AppKit
import Foundation
import Testing
@testable import DesignScaffoldProbe

/// The channel a driver reads and commands over accessibility. The tests run the host's two
/// entry points directly: `serialized()` (an AX read) and `run(_:)` (an AX write).
@MainActor
@Suite(.serialized) struct ProbeChannelTests {
    init() {
        UserDefaults.standard.set(true, forKey: "DesignScaffoldProbe")
        HitTestProbe.emit = { _ in }
    }

    func snapshot() throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: Data(ProbeChannel.serialized().utf8)) as? [String: Any])
    }

    func run(_ command: String, _ args: [String: Any] = [:], id: String = UUID().uuidString) throws -> [String: Any] {
        let text = String(decoding: try JSONSerialization.data(withJSONObject: ["id": id, "command": command, "args": args]), as: UTF8.self)
        ProbeChannel.run(text)
        let reply = try #require(try snapshot()["reply"] as? [String: Any])
        #expect(reply["id"] as? String == id, "the reply answers this command, not an earlier one")
        return reply
    }

    @Test func stateIsComputedAtReadTime() throws {
        var count = 1
        HitTestProbe.state("counter") { ["count": count, "frame": CGRect(x: 1, y: 2, width: 3, height: 4)] }
        defer { HitTestProbe.removeState("counter") }
        count = 7
        let state = try #require(try snapshot()["state"] as? [String: Any])
        let counter = try #require(state["counter"] as? [String: Any])
        #expect(counter["count"] as? Int == 7)
        #expect((counter["frame"] as? [String: Any])?["w"] as? Double == 3)
    }

    @Test func commandsRunWithTheirArgumentsAndReply() throws {
        HitTestProbe.command("add") { args in
            let p = try args.point("p")
            return ["sum": p.x + p.y, "list": try args.points("ps").count]
        }
        defer { HitTestProbe.removeCommand("add") }
        let reply = try run("add", ["p": [2, 3], "ps": [[0, 0], ["x": 1, "y": 1]]])
        #expect(reply["ok"] as? Bool == true)
        let result = try #require(reply["result"] as? [String: Any])
        #expect(result["sum"] as? Double == 5)
        #expect(result["list"] as? Int == 2)
    }

    @Test func aThrowingCommandRepliesWithItsError() throws {
        HitTestProbe.command("fail") { _ in throw ProbeError("no document open") }
        defer { HitTestProbe.removeCommand("fail") }
        let reply = try run("fail")
        #expect(reply["ok"] as? Bool == false)
        #expect(reply["error"] as? String == "no document open")
        #expect(try run("nope")["ok"] as? Bool == false)
    }

    @Test func eventsAreNumberedAndReadSinceASeq() throws {
        let before = ProbeChannel.lastSeq
        HitTestProbe.commit("stroke", "pad", "points=12")
        HitTestProbe.event("EXPORTED", "png")
        let reply = try run("events", ["since": before])
        let result = try #require(reply["result"] as? [String: Any])
        let events = try #require(result["events"] as? [[String: Any]])
        #expect(events.map { $0["kind"] as? String } == ["COMMIT", "EXPORTED"])
        #expect(events.first?["detail"] as? String == "stroke pad points=12")
        #expect(events.last?["seq"] as? Int == before + 2)
        #expect(try snapshot()["last_seq"] as? Int == before + 2)
    }

    @Test func aMalformedCommandIsRefusedNotIgnored() throws {
        ProbeChannel.run("not json")
        let reply = try #require(try snapshot()["reply"] as? [String: Any])
        #expect(reply["ok"] as? Bool == false)
    }

    @Test func inputReachesAnAppKitViewWithoutThePointer() throws {
        final class Pad: NSView {
            var log: [String] = []
            override func mouseDown(with e: NSEvent) { log.append("down \(convert(e.locationInWindow, from: nil))") }
            override func mouseDragged(with e: NSEvent) { log.append("drag") }
            override func mouseUp(with e: NSEvent) { log.append("up \(convert(e.locationInWindow, from: nil))") }
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: [.titled],
                              backing: .buffered, defer: true)
        let pad = Pad(frame: NSRect(x: 10, y: 10, width: 100, height: 100))
        window.contentView?.addSubview(pad)
        try ProbeInput.drag(pad, from: CGPoint(x: 5, y: 5), to: CGPoint(x: 50, y: 40), steps: 3)
        #expect(pad.log == ["down (5.0, 5.0)", "drag", "drag", "drag", "up (50.0, 40.0)"])
    }
}
#endif
