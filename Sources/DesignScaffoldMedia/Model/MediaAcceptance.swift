//
//  ⚠️ macOS-only. This target is wrapped in `#if os(macOS)` because it is built on AppKit
//  API with no iOS equivalent — see `Docs/PLATFORMS.md`. On iOS the module compiles to
//  nothing, so an app that adds this product by mistake gets "cannot find X in scope"
//  rather than a wall of AppKit errors, and the package as a whole still builds.
//
#if os(macOS)

//
//  MediaAcceptance.swift
//  DesignScaffoldMedia
//
//  Which dropped files a well will take — the part of ``MediaWell`` that is a decision
//  rather than a drawing, and therefore the part that can be tested.
//

import Foundation
import UniformTypeIdentifiers

/// Splits a dropped batch into what a well accepts and what it does not.
///
/// ## ⚠️ None of the six copies this was promoted from checked anything
///
/// Every one of them handed whatever was dropped straight to `NSImage(contentsOf:)` or
/// equivalent. Drop a `.txt` on an image well and the loader returns nil, the guard falls
/// through to a bare `else { return }`, and **nothing happens at all** — no image, no
/// message, no indication the app even noticed. Filtering here means the host can say so.
public enum MediaAcceptance {

    /// The content type of a file on disk, or `nil` if it cannot be determined.
    ///
    /// ⚠️ Reads the **file's** type rather than guessing from the path extension.
    /// `UTType(filenameExtension:)` is a lookup in a table that does not know about this
    /// file: it answers for a `.png` that is really a renamed PDF, and answers nothing at
    /// all for an extensionless file that the system types correctly.
    public static func contentType(of url: URL) -> UTType? {
        (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
            ?? UTType(filenameExtension: url.pathExtension)
    }

    /// Whether `url` is something a well allowing `types` should take.
    public static func accepts(_ url: URL, types: [UTType]) -> Bool {
        guard !types.isEmpty else { return true }
        guard let type = contentType(of: url) else { return false }
        return types.contains { type.conforms(to: $0) }
    }

    /// Partitions a drop into `accepted` and `rejected`, preserving order in both.
    ///
    /// Order matters: a multi-select well shows the files in the order they arrived, and a
    /// single-file well takes `accepted.first` — which must be the first file the user
    /// dropped, not the first one that happened to survive a `Set`.
    public static func partition(_ urls: [URL],
                                 types: [UTType]) -> (accepted: [URL], rejected: [URL]) {
        var accepted: [URL] = [], rejected: [URL] = []
        for url in urls {
            if accepts(url, types: types) { accepted.append(url) } else { rejected.append(url) }
        }
        return (accepted, rejected)
    }
}

#endif
