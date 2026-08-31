//
//  LabApp.swift
//  iOS Design Workspace
//
//  The Component Lab, on a device.
//
//  ⚠️ This is a SEPARATE lab from the macOS one, deliberately, and the reason is that they
//  answer different questions. The macOS harnesses exist because every defect this package
//  has shipped was found by a POINTER — context-menu precedence, hit testing under a
//  collapsed frame, a gesture dying on a mid-drag rebuild. None of that is a touch concern.
//
//  What touch asks instead is whether a component can be OPERATED: whether its hit area
//  clears 44pt, whether a drag idiom that begins instantly with a mouse still makes sense
//  after a long press, whether a three-pane desktop shell means anything on a phone. That is
//  what `Docs/PLATFORMS.md` marks Tier 2 as unverified for, and it is what this target is
//  for.
//
//  Sharing the macOS harnesses would have meant either a synchronized-folder exception set
//  or extracting them into a local package. Both cost more than they save while the two labs
//  are asking different questions — but if this one grows toward the other, extract rather
//  than copy.
//

import SwiftUI

@main
struct LabApp: App {
    var body: some Scene {
        WindowGroup {
            IOSLabView()
        }
    }
}
