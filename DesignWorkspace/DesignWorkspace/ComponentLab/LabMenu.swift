//
//  LabMenu.swift
//  DesignWorkspace — Component Lab
//
//  A programmatic menu bar, installed only under `-MainMenu`.
//
//  ⚠️ This exists as an EXPERIMENTAL VARIABLE, not as app chrome. A consumer measured context-
//  menu precedence INVERTED from this lab's result — same component source, same machine, same
//  configuration — and after eliminating chronology, view ancestry, hosting class, the drag
//  gestures, and (measurably) the App Sandbox, the last named structural difference between the
//  two apps was that theirs installs a main menu and this one installs none at all.
//
//  A no-IB AppKit app gets NO menu unless one is built, so "none" was never a choice here — it
//  was the default nobody had reason to question. Transcribed from their `AppMenu.swift` so the
//  variable is theirs and not an approximation of it.
//

import AppKit

@MainActor
enum LabMenu {
    /// True when the process was launched to run with a menu bar installed.
    static var requested: Bool { CommandLine.arguments.contains("-MainMenu") }

    static func install() {
        let main = NSMenu()
        let name = ProcessInfo.processInfo.processName

        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About \(name)",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                        keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide \(name)",
                        action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit \(name)",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        // Without an Edit menu the standard text shortcuts do nothing — and, more to the point
        // here, the responder chain has no menu items validating against it.
        let editItem = NSMenuItem()
        main.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All",
                         action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        NSApp.mainMenu = main
    }
}
