//
//  Separator.swift
//  DesignScaffold
//
//  The hairline. Vocabulary, not a component — it belongs beside `cardSurface()`.
//

import SwiftUI

/// A one-point rule in the separator colour.
///
/// It exists because every app in the fleet had hand-rolled it, and not identically:
/// `Rectangle().fill(someElevatedFill).frame(width: 1)` for pane edges,
/// `Divider().overlay(someElevatedFill)` for section rules. Two idioms, two colour choices,
/// and in ML[X] Media Forge a doc comment promising "a hairline separator marks its edge"
/// above a layout that draws none — the primitive was missing, so the intent stayed a comment.
///
/// ⚠️ **It is greedy along its own length.** `Separator(.vertical)` fills the height it is
/// offered, which is what you want between panes in an `HStack` and a bug anywhere the
/// parent's size is derived from its children — a greedy vertical rule inflated a timeline's
/// ruler row and pushed a track out of frame. In an unconstrained context, state the length:
/// `Separator(.vertical).frame(height: 24)`.
public struct Separator: View {
    public enum Axis: Sendable { case horizontal, vertical }

    private let axis: Axis
    private let color: Color

    /// - Parameters:
    ///   - axis: `.horizontal` draws a full-width rule; `.vertical` a full-height one.
    ///   - color: defaults to the semantic separator colour. Override only for a surface
    ///     whose contrast genuinely demands it — a hairline that differs per app is the
    ///     thing this type exists to end.
    public init(_ axis: Axis, color: Color = Tokens.Color.separator) {
        self.axis = axis
        self.color = color
    }

    public var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: axis == .vertical ? Tokens.Layout.hairline : nil,
                   height: axis == .horizontal ? Tokens.Layout.hairline : nil)
            .frame(maxWidth: axis == .horizontal ? .infinity : nil,
                   maxHeight: axis == .vertical ? .infinity : nil)
            // A rule is decoration; it must never take a click meant for what it sits between.
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
