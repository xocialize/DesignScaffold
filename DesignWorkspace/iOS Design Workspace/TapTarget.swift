//
//  TapTarget.swift
//  iOS Design Workspace
//
//  Makes the 44pt minimum visible instead of arguable.
//

import DesignScaffold
import SwiftUI

/// Apple's minimum comfortable hit area. Not a token: it is a platform HIG constant, and
/// putting it in `Tokens` would imply the design system chose it.
enum TapTarget {
    static let minimum: CGFloat = 44
}

/// Draws the 44pt minimum behind a control and reports what the control actually measures.
///
/// ## Why this is the first thing the iOS lab does
///
/// `Docs/PLATFORMS.md` records that `Tokens.Layout.controlHeight` is **24** and `rowHeight`
/// is **42**, both under the 44pt minimum — and that the geometry tokens came from a macOS
/// Figma kit that was never asked to be anything else. That is a claim derived by reading
/// numbers. This renders it: the band is 44pt, the control sits inside it, and any shortfall
/// is the gap you can see.
struct TapTargetBand: ViewModifier {
    let label: String
    let show: Bool
    @Binding var measured: [String: CGFloat]

    func body(content: Content) -> some View {
        content
            // ⚠️ A PreferenceKey, not `onChange(of:initial:)` — that overload is iOS 17 and
            // this package floors at 16. Caught by the iOS lab failing to build against its
            // own floor, which is a reasonable thing for the lab to be good at.
            .background {
                GeometryReader { geo in
                    Color.clear.preference(key: MeasuredHeightKey.self,
                                           value: [label: geo.size.height])
                }
            }
            .onPreferenceChange(MeasuredHeightKey.self) { heights in
                for (k, v) in heights where measured[k] != v { measured[k] = v }
            }
            .background(alignment: .center) {
                if show {
                    RoundedRectangle(cornerRadius: Tokens.Radius.control)
                        .strokeBorder(passes ? Tokens.Color.ready : Tokens.Color.failure,
                                      style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        .frame(height: TapTarget.minimum)
                        .allowsHitTesting(false)
                }
            }
    }

    private var passes: Bool { (measured[label] ?? 0) >= TapTarget.minimum }
}

private struct MeasuredHeightKey: PreferenceKey {
    static let defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    func tapTargetBand(_ label: String, show: Bool,
                       measured: Binding<[String: CGFloat]>) -> some View {
        modifier(TapTargetBand(label: label, show: show, measured: measured))
    }
}
