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
/// What the band is wrapped around — because the answer changes whether it means anything.
enum TapTargetKind {
    /// A single interactive element. Its height IS its hit area, so a verdict is meaningful.
    case control
    /// A container of many interactive elements. Its height is NOT any element's hit area,
    /// so this reports the number and REFUSES a verdict.
    case container
}

struct TapTargetBand: ViewModifier {
    let label: String
    let kind: TapTargetKind
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
                // ⚠️ Only drawn for a CONTROL. A 44pt band centred on a 220pt list lands in
                // the middle of it and looks like a verdict on whatever row it happens to
                // cross — which is how this instrument reported "calendar 245pt ✅" and meant
                // nothing at all by it.
                if show, kind == .control {
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

/// A reading, and whether it is allowed to be a verdict.
struct TapTargetReading {
    let height: CGFloat
    let kind: TapTargetKind

    var verdict: String {
        switch kind {
        case .control:   return height >= TapTarget.minimum ? "pass" : "FAILS"
        case .container: return "container — no verdict"
        }
    }
}

private struct MeasuredHeightKey: PreferenceKey {
    static let defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    func tapTargetBand(_ label: String, _ kind: TapTargetKind = .control, show: Bool,
                       measured: Binding<[String: CGFloat]>) -> some View {
        modifier(TapTargetBand(label: label, kind: kind, show: show, measured: measured))
    }
}
