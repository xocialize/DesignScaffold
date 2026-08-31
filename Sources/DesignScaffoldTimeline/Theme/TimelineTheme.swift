//
//  ⚠️ macOS-only. This target is wrapped in `#if os(macOS)` because it is built on AppKit
//  API with no iOS equivalent — see `Docs/PLATFORMS.md`. On iOS the module compiles to
//  nothing, so an app that adds this product by mistake gets "cannot find X in scope"
//  rather than a wall of AppKit errors, and the package as a whole still builds.
//
#if os(macOS)

import DesignScaffold
import SwiftUI

/// Visual styling for a ``TimelineView``. Initializer defaults are the token values, so a
/// custom theme that only overrides colours still inherits the spec geometry.
///
/// PROVENANCE: the "Timeline anatomy" artboard of the LTX Studio editor canvas (AB-A-0031),
/// whose measurements are token references throughout. Two spec values were changed on the
/// way in, both recorded below rather than applied silently.
public struct TimelineTheme: Sendable {

    // MARK: Colours

    /// Selection ring/fill on a clip.
    ///
    /// ⚠️ **Changed from the spec.** The artboard specifies `accentFigma` (the kit's literal
    /// #0091ff). Defaulting to the *system* accent instead keeps the timeline consistent
    /// with every other scaffold component and honours the user's accent choice and
    /// Increase Contrast — the whole reason AB-D-0042 prefers semantics over literals. An
    /// editor that genuinely wants a fixed brand blue regardless of system settings sets
    /// `theme.selection = Tokens.Color.accentFigma`; that is a deliberate app override, not
    /// the library default.
    public var selection: Color
    /// Wash behind a selected clip body.
    public var selectionWash: Color

    /// The playhead.
    ///
    /// ⚠️ **Decoupled from the spec's wording.** The artboard says "failure #ff4245", and
    /// `Tokens.Color.failure` does carry that value today — but a playhead is not an error,
    /// and binding it to the failure semantic means a future change to error red silently
    /// moves the playhead. Carried as its own literal (the kit's Accents/Red), which is
    /// also the editing-tool convention.
    public var playhead: Color

    public var rulerBackground: Color
    public var rulerTick: Color
    public var rulerLabel: Color
    public var headerBackground: Color
    public var laneBackground: Color
    /// Alternating lane tint so rows are separable without a heavy border.
    public var laneAlternate: Color
    public var separator: Color
    public var trackName: Color
    public var controlOff: Color
    public var controlOn: Color
    /// Fill behind a clip when the consumer's body is transparent.
    public var clipBackground: Color

    // MARK: Metrics (artboard "Geometry")

    public var headerWidth: CGFloat
    public var rulerHeight: CGFloat
    public var clipInset: CGFloat
    public var clipRadius: CGFloat
    public var panelRadius: CGFloat
    public var hairline: CGFloat
    /// Edge-drag trim handle width (T2 uses it; sized here so T1 renders the affordance).
    public var trimHandleWidth: CGFloat
    /// Snap threshold **in points** — converted to seconds per zoom via
    /// ``TimelineGeometry/seconds(forPoints:)``, never stored as a duration.
    public var snapThreshold: CGFloat
    /// Minimum spacing between ruler labels before the tick interval steps up a rung.
    public var minTickSpacing: CGFloat
    public var playheadWidth: CGFloat

    // MARK: Fonts

    public var trackNameFont: Font
    public var timecodeFont: Font
    public var clipLabelFont: Font

    public init(
        selection: Color = Tokens.Color.accent,
        selectionWash: Color = Tokens.Color.selectionWash,
        playhead: Color = Color(red: 0xff / 255, green: 0x42 / 255, blue: 0x45 / 255),
        rulerBackground: Color = Tokens.Color.surfaceElevated,
        rulerTick: Color = Tokens.Color.tertiaryLabel,
        rulerLabel: Color = Tokens.Color.secondaryLabel,
        headerBackground: Color = Tokens.Color.surfaceElevated,
        laneBackground: Color = Tokens.Color.surface,
        laneAlternate: Color = Tokens.Color.fillElevated,
        separator: Color = Tokens.Color.separator,
        trackName: Color = Tokens.Color.label,
        controlOff: Color = Tokens.Color.tertiaryLabel,
        controlOn: Color = Tokens.Color.accent,
        clipBackground: Color = Tokens.Color.fillElevated,
        headerWidth: CGFloat = 200,
        rulerHeight: CGFloat = 28,
        clipInset: CGFloat = Tokens.Space.xs,
        clipRadius: CGFloat = Tokens.Radius.control,
        panelRadius: CGFloat = Tokens.Radius.container,
        hairline: CGFloat = Tokens.Layout.hairline,
        trimHandleWidth: CGFloat = 8,
        snapThreshold: CGFloat = 8,
        minTickSpacing: CGFloat = 56,
        playheadWidth: CGFloat = 1,
        trackNameFont: Font = Tokens.Font.caption,
        timecodeFont: Font = Tokens.Font.monoSmall,
        clipLabelFont: Font = Tokens.Font.caption
    ) {
        self.selection = selection
        self.selectionWash = selectionWash
        self.playhead = playhead
        self.rulerBackground = rulerBackground
        self.rulerTick = rulerTick
        self.rulerLabel = rulerLabel
        self.headerBackground = headerBackground
        self.laneBackground = laneBackground
        self.laneAlternate = laneAlternate
        self.separator = separator
        self.trackName = trackName
        self.controlOff = controlOff
        self.controlOn = controlOn
        self.clipBackground = clipBackground
        self.headerWidth = headerWidth
        self.rulerHeight = rulerHeight
        self.clipInset = clipInset
        self.clipRadius = clipRadius
        self.panelRadius = panelRadius
        self.hairline = hairline
        self.trimHandleWidth = trimHandleWidth
        self.snapThreshold = snapThreshold
        self.minTickSpacing = minTickSpacing
        self.playheadWidth = playheadWidth
        self.trackNameFont = trackNameFont
        self.timecodeFont = timecodeFont
        self.clipLabelFont = clipLabelFont
    }
}

public extension TimelineTheme {
    /// The house style, and the default.
    static var scaffold: TimelineTheme { TimelineTheme() }
}

#endif
