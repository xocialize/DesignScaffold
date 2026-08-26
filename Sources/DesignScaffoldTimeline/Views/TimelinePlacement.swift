import SwiftUI

/// Places a clip in its lane by **layout**, not by `.offset`.
///
/// ⚠️ This exists because of a measured bug (AB-A-0031, fixed in 0.6.1). `.offset` displaces
/// only the *drawing*: the view's layout frame stays where it was, so `.contentShape` — and
/// with it the whole hit region — anchors at the lane's left edge no matter what time the
/// clip is at. Every clip's hit region then overlaps at x = 0 and z-order decides which one
/// a click lands on, which is how a tap over one clip selected a different clip entirely.
/// Rendering looked perfect throughout, and every test that called the edit API directly
/// passed, because the edit math was never wrong.
///
/// Measured, so it does not have to be recalled:
///
/// ```
/// offset      B expected x=120  measured x=0.0     ← drawing moves, layout does not
/// alignGuide  B expected x=120  measured x=120.0
/// ```
///
/// **Do not "simplify" this back to `.offset`.** `TimelinePlacementTests` fails if you do.
struct TimelinePlacement: ViewModifier {
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content
            .alignmentGuide(.leading) { _ in -x }
            .alignmentGuide(.top) { _ in -y }
    }
}

extension View {
    /// Position within a `ZStack(alignment: .topLeading)` lane so that drawing **and hit
    /// testing** both land at `(x, y)`.
    func timelinePlaced(x: CGFloat, y: CGFloat) -> some View {
        modifier(TimelinePlacement(x: x, y: y))
    }
}

