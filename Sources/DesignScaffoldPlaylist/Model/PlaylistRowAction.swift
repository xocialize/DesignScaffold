//
//  PlaylistRowAction.swift
//  DesignScaffoldPlaylist
//

import Foundation

/// One icon button in a row's trailing column — the app's intent, rendered by the component.
///
/// ## Declarative on purpose
///
/// The trailing column could have been a bare `ViewBuilder`, and there is one
/// (``PlaylistIterator/rowAccessory(_:)``) for the genuinely custom case. It is not the
/// primary API, because every real row-icon set on the volume turned out to be the same three
/// things: ML[X] Audio Studio's take row is a **toggle** (favourite: `star` / `star.fill`,
/// amber when on), a plain **action** (export) and a **destructive** one (delete) — and it
/// had put the toggle's *state* into the row by prefixing "★ " to the name string, in three
/// separate views, because the list had nowhere else to show it. That is a screen reader
/// announcing a star glyph as part of a title.
///
/// Given intent rather than a view, the component owns everything an app would otherwise
/// re-decide: the button style, the on/destructive tints, the hover tooltip, the
/// accessibility label and selected trait, keeping the button out of the row's drag and
/// select gestures — and the 44pt hit floor on iOS.
public struct PlaylistRowAction: Identifiable {

    public enum Role: Sendable { case normal, destructive }

    public let id: String
    /// Tooltip on macOS; the accessibility label everywhere.
    public let label: String
    public let symbol: String
    /// The symbol while a toggle is on. `nil` follows the SF Symbols `.fill` convention.
    public let onSymbol: String?
    /// `nil` for a plain action; a `Bool` makes this a toggle and renders its state.
    public let isOn: Bool?
    public let role: Role
    public let handler: @MainActor () -> Void

    public init(id: String, label: String, symbol: String, onSymbol: String? = nil,
                isOn: Bool? = nil, role: Role = .normal,
                handler: @escaping @MainActor () -> Void) {
        self.id = id
        self.label = label
        self.symbol = symbol
        self.onSymbol = onSymbol
        self.isOn = isOn
        self.role = role
        self.handler = handler
    }

    // MARK: Conveniences — the three shapes found on the volume

    /// A plain action. `id` defaults to the label.
    public static func action(_ label: String, symbol: String, id: String? = nil,
                              handler: @escaping @MainActor () -> Void) -> PlaylistRowAction {
        .init(id: id ?? label, label: label, symbol: symbol, handler: handler)
    }

    /// A toggle that renders its state. Off shows `symbol`; on shows `onSymbol`, or
    /// `symbol + ".fill"` when that is not given — `star` → `star.fill`, `heart` → `heart.fill`.
    public static func toggle(_ label: String, symbol: String, onSymbol: String? = nil,
                              isOn: Bool, id: String? = nil,
                              handler: @escaping @MainActor () -> Void) -> PlaylistRowAction {
        .init(id: id ?? label, label: label, symbol: symbol, onSymbol: onSymbol,
              isOn: isOn, handler: handler)
    }

    /// An action that removes or discards. Tinted `failure`.
    public static func destructive(_ label: String, symbol: String, id: String? = nil,
                                   handler: @escaping @MainActor () -> Void) -> PlaylistRowAction {
        .init(id: id ?? label, label: label, symbol: symbol, role: .destructive, handler: handler)
    }

    // MARK: Resolution (pure, tested)

    /// The symbol to draw right now.
    public var resolvedSymbol: String {
        guard isOn == true else { return symbol }
        return onSymbol ?? symbol + ".fill"
    }

    /// Whether this is a toggle currently on — drives the tint and the selected trait.
    public var isToggledOn: Bool { isOn == true }
}
