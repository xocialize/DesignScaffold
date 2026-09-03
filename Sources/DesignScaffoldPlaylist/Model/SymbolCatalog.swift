//
//  SymbolCatalog.swift
//  DesignScaffoldPlaylist
//
//  Does this SF Symbol name exist on this platform?
//

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Answers "will `Image(systemName:)` draw anything for this name?" — because when the
/// answer is no, SwiftUI draws nothing and says nothing.
///
/// Resolved once per name and cached, so the check costs a dictionary lookup per draw rather
/// than an image load. In `DEBUG`, a missing name is logged the first time it is asked for —
/// the one thing that would have saved MarqueeStudio the eyeball (AB-A-0058).
public enum SymbolCatalog {

    private static let lock = NSLock()
    nonisolated(unsafe) private static var cache: [String: Bool] = [:]

    public static func exists(_ name: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if let known = cache[name] { return known }
        let found = probe(name)
        cache[name] = found
        #if DEBUG
        if !found {
            print("DesignScaffoldPlaylist: no SF Symbol named \"\(name)\" — falling back to the base symbol")
        }
        #endif
        return found
    }

    private static func probe(_ name: String) -> Bool {
        #if canImport(AppKit)
        NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        #elseif canImport(UIKit)
        UIImage(systemName: name) != nil
        #else
        true
        #endif
    }
}
