//
//  PlaylistRowState.swift
//  DesignScaffoldPlaylist
//

import Foundation

/// What the *player* will do with a row — not what the list allows.
///
/// ## Two visual states, app-defined semantics
///
/// The component knows only how each renders: `unavailable` dims the row; `disabled` dims it
/// and strikes the name. What they *mean* is the host's. MarqueeStudio's `unavailable` is
/// "no file for this orientation / missing locally / not playable here" and flips live with
/// the orientation toggle; its `disabled` is an authored skip flag. Another app may use only
/// one, or neither.
///
/// ⚠️ **Rows stay selectable and draggable in every state.** The order is still the
/// operator's to set; the state describes what the sequencer will skip, not what the list
/// refuses. A struck-through row that could not be dragged out of the way would be actively
/// in the way.
///
/// `reason` becomes the row's tooltip and is folded into its accessibility label, so
/// VoiceOver hears *why* and not just that something is greyed.
public enum PlaylistRowState: Equatable, Sendable {
    case normal
    case unavailable(reason: String? = nil)
    case disabled(reason: String? = nil)

    /// Name and metadata drawn in the theme's dimmed colour.
    public var isDimmed: Bool {
        if case .normal = self { return false }
        return true
    }

    /// Name struck through — the row is authored out, not merely absent.
    public var isStruck: Bool {
        if case .disabled = self { return true }
        return false
    }

    public var reason: String? {
        switch self {
        case .normal: return nil
        case .unavailable(let r), .disabled(let r): return r
        }
    }

    /// The spoken prefix VoiceOver adds before the name.
    var accessibilityPrefix: String? {
        switch self {
        case .normal: return nil
        case .unavailable(let r): return r.map { "unavailable, \($0)" } ?? "unavailable"
        case .disabled(let r): return r.map { "skipped, \($0)" } ?? "skipped"
        }
    }
}
