// Exact-coordinate input driver for component verification.
//
// Adapted from ML[X] LTX Studio's Tools/drag.swift (AB-A-0031) — with the two details that
// make synthetic input actually register, both of which I had missing and which made an
// earlier harness silently inert:
//
//  1. A REAL `CGEventSource`. SwiftUI reads the source's button state; events posted with a
//     nil source arrive as moves with no button held.
//  2. `mouseEventClickState` set on down/drag/up. Without it a click is not a click.
//
// A double-click is ONE pair with clickState 2 — AppKit reads the state field, not the
// interval, so two fast clicks are two single clicks however fast they arrive.
//
// usage: inputdriver click|rightclick|doubleclick <x> <y>
//        inputdriver drag <x1> <y1> <x2> <y2> [steps]
//        inputdriver move <x> <y>

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

// nonisolated: top-level `let` is main-actor isolated in Swift 6, and the post
// helpers are not.
nonisolated(unsafe) let source = CGEventSource(stateID: .hidSystemState)

func post(_ type: CGEventType, _ p: CGPoint, button: CGMouseButton = .left, clickState: Int64 = 1) {
    guard let e = CGEvent(mouseEventSource: source, mouseType: type,
                          mouseCursorPosition: p, mouseButton: button) else { return }
    switch type {
    case .leftMouseDown, .leftMouseUp, .leftMouseDragged,
         .rightMouseDown, .rightMouseUp, .rightMouseDragged:
        e.setIntegerValueField(.mouseEventClickState, value: clickState)
    default:
        break
    }
    e.post(tap: .cghidEventTap)
}

func point(_ i: Int) -> CGPoint {
    CGPoint(x: Double(CommandLine.arguments[i])!, y: Double(CommandLine.arguments[i + 1])!)
}

/// ⚠️ Posting to the HID tap silently does NOTHING when the calling process is not trusted
/// for Accessibility — no error, no event. That is how a harness reports "the app ignored my
/// click" for a bug that does not exist. Refuse loudly instead.
func requireTrust() {
    guard !AXIsProcessTrusted() else { return }
    FileHandle.standardError.write(Data("""
    inputdriver: NOT TRUSTED FOR ACCESSIBILITY — refusing to post events.

    CGEvent.post() to the HID tap is a silent no-op for an untrusted process, so running
    anyway would produce false "the app ignored it" results.

    Grant the PARENT process (the terminal or agent running this) Accessibility in
    System Settings ▸ Privacy & Security ▸ Accessibility, then re-run.

    `inputdriver windows` works without trust and is safe to use meanwhile.

    """.utf8))
    exit(3)
}

let args = CommandLine.arguments
guard args.count > 1 else {
    print("usage: inputdriver click|rightclick|doubleclick|move <x> <y> | drag <x1> <y1> <x2> <y2> [steps]")
    exit(2)
}

switch args[1] {
case "activate":
    // ⚠️ A click into a BACKGROUND window is consumed activating it, so the first synthetic
    // click of a run registers as nothing and the harness reads as broken. Bring the target
    // frontmost first — this is what made an otherwise-correct driver look inert.
    let wanted = args.count > 2 ? args[2] : ""
    let running = NSWorkspace.shared.runningApplications.filter {
        ($0.localizedName ?? "").contains(wanted) || ($0.bundleIdentifier ?? "").contains(wanted)
    }
    guard let app = running.first else {
        FileHandle.standardError.write(Data("inputdriver: no running app matching \(wanted)\n".utf8))
        exit(4)
    }
    app.activate(options: [.activateAllWindows])
    usleep(400_000)
    print("activated \(app.localizedName ?? wanted)")

case "trust":
    print(AXIsProcessTrusted() ? "trusted — events will post"
                              : "NOT trusted — events would be silently dropped")

case "windows":
    // Window bounds in the SAME top-left screen space CGEvent uses, so a caller never has to
    // convert. No accessibility permission needed for this listing.
    let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                          kCGNullWindowID) as? [[String: Any]] ?? []
    for w in info {
        guard let name = w[kCGWindowOwnerName as String] as? String,
              let boundsDict = w[kCGWindowBounds as String] as? [String: Any],
              let b = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
              b.width > 200, b.height > 100 else { continue }
        let title = (w[kCGWindowName as String] as? String) ?? ""
        let filter = args.count > 2 ? args[2] : ""
        guard filter.isEmpty || name.contains(filter) || title.contains(filter) else { continue }
        print(String(format: "%-28s %-42s x=%.0f y=%.0f w=%.0f h=%.0f",
                     (name as NSString).utf8String!, (title as NSString).utf8String!,
                     b.minX, b.minY, b.width, b.height))
    }

case "move":
    requireTrust()
    post(.mouseMoved, point(2))

case "click":
    requireTrust()
    let p = point(2)
    post(.mouseMoved, p); usleep(80_000)
    post(.leftMouseDown, p); usleep(60_000); post(.leftMouseUp, p)

case "rightclick":
    requireTrust()
    let p = point(2)
    post(.mouseMoved, p); usleep(80_000)
    post(.rightMouseDown, p, button: .right); usleep(60_000)
    post(.rightMouseUp, p, button: .right)

case "doubleclick":
    requireTrust()
    let p = point(2)
    post(.mouseMoved, p); usleep(80_000)
    for state in Int64(1)...2 {
        post(.leftMouseDown, p, clickState: state); usleep(40_000)
        post(.leftMouseUp, p, clickState: state); usleep(40_000)
    }

case "drag":
    requireTrust()
    let a = point(2), b = point(4)
    let steps = args.count > 6 ? Int(args[6])! : 24
    post(.mouseMoved, a); usleep(80_000)
    post(.leftMouseDown, a); usleep(80_000)
    for i in 1...steps {
        let t = Double(i) / Double(steps)
        post(.leftMouseDragged, CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
        usleep(16_000)
    }
    usleep(100_000)
    post(.leftMouseUp, b)

default:
    print("unknown command \(args[1])"); exit(2)
}
