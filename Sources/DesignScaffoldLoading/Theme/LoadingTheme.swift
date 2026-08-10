import DesignScaffold
import SwiftUI

/// Visual styling for a ``LoadingCard``.
///
/// The default theme is ``scaffold`` — resolved through `Tokens`. The initialiser's
/// defaults are the token values, so a custom theme that only overrides colours still
/// inherits the scaffold geometry.
///
/// PROVENANCE: the LAYOUT mirrors the Bonsai 27B WebGPU space's loading readout
/// (bottom-left block: display-size percentage with a smaller muted % suffix, a status
/// line over a dot-separated detail line, a thin progress bar, content as backdrop).
/// The TYPE AND COLOUR are deliberately ours, not the site's: semantic label ramp
/// instead of its fixed dark palette, the kit's caption/mono fonts instead of its
/// heavily-tracked SF Mono, and an accent bar instead of its prism gradient (kept
/// available as ``prismBarColors`` for when a surface wants the reference look).
public struct LoadingTheme: Sendable {

    // Colours
    public var percentText: Color
    /// The smaller "%" suffix beside the number.
    public var percentSymbol: Color
    public var statusText: Color
    public var fieldsText: Color
    public var titleText: Color
    /// The thin bar's unfilled track.
    public var barTrack: Color
    /// The bar fill, leading → trailing. One colour = solid; several = a gradient
    /// (``prismBarColors`` is the reference look).
    public var barColors: [Color]
    /// Dimming behind the card when presented as a modal.
    public var backdrop: Color
    /// Legibility gradient drawn behind the readout when a background view is set
    /// (fades from this at the bottom-left to clear). Pair imagery with
    /// `.preferredColorScheme(.dark)` so the semantic text resolves light.
    public var scrim: Color
    /// Card fill when no background view is supplied.
    public var cardSurface: Color
    public var cardBorder: Color

    // Metrics
    public var cardWidth: CGFloat
    public var cardHeight: CGFloat
    public var cardRadius: CGFloat
    /// Inset of the readout (and title) from the card edges.
    public var readoutPadding: CGFloat
    public var barWidth: CGFloat
    public var barHeight: CGFloat
    /// Tracking on the uppercase status line (the fleet's micro-header treatment).
    public var statusTracking: CGFloat

    // Fonts
    /// The hero number. Display-thin and monospaced-digit so live updates don't jitter.
    public var percentFont: Font
    /// The "%" suffix.
    public var percentSymbolFont: Font
    public var statusFont: Font
    public var fieldsFont: Font
    public var titleFont: Font

    public init(
        percentText: Color = Tokens.Color.label,
        percentSymbol: Color = Tokens.Color.secondaryLabel,
        statusText: Color = Tokens.Color.secondaryLabel,
        fieldsText: Color = Tokens.Color.tertiaryLabel,
        titleText: Color = Tokens.Color.secondaryLabel,
        barTrack: Color = Tokens.Color.separator,
        barColors: [Color] = [Tokens.Color.accent],
        backdrop: Color = SwiftUI.Color.black.opacity(0.35),
        scrim: Color = SwiftUI.Color.black.opacity(0.45),
        cardSurface: Color = Tokens.Color.surface,
        cardBorder: Color = Tokens.Color.separator,
        cardWidth: CGFloat = 800,
        cardHeight: CGFloat = 600,
        cardRadius: CGFloat = Tokens.Radius.large,
        readoutPadding: CGFloat = Tokens.Space.xxl,
        barWidth: CGFloat = 300,
        barHeight: CGFloat = 2,
        statusTracking: CGFloat = 0.6,
        percentFont: Font = SwiftUI.Font.system(size: 96, weight: .ultraLight).monospacedDigit(),
        percentSymbolFont: Font = SwiftUI.Font.system(size: 40, weight: .light),
        statusFont: Font = Tokens.Font.caption.weight(.semibold),
        fieldsFont: Font = Tokens.Font.monoSmall,
        titleFont: Font = Tokens.Font.sectionTitle
    ) {
        self.percentText = percentText
        self.percentSymbol = percentSymbol
        self.statusText = statusText
        self.fieldsText = fieldsText
        self.titleText = titleText
        self.barTrack = barTrack
        self.barColors = barColors
        self.backdrop = backdrop
        self.scrim = scrim
        self.cardSurface = cardSurface
        self.cardBorder = cardBorder
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.cardRadius = cardRadius
        self.readoutPadding = readoutPadding
        self.barWidth = barWidth
        self.barHeight = barHeight
        self.statusTracking = statusTracking
        self.percentFont = percentFont
        self.percentSymbolFont = percentSymbolFont
        self.statusFont = statusFont
        self.fieldsFont = fieldsFont
        self.titleFont = titleFont
    }
}

public extension LoadingTheme {

    /// The house style, and the default — resolved through `Tokens`.
    static var scaffold: LoadingTheme { LoadingTheme() }

    /// The reference site's prism bar gradient (white → red → gold → green → blue →
    /// violet), for surfaces that want the Bonsai look:
    /// `var t = LoadingTheme.scaffold; t.barColors = LoadingTheme.prismBarColors`.
    static let prismBarColors: [Color] = [
        SwiftUI.Color(red: 0xf4 / 255, green: 0xf6 / 255, blue: 0xff / 255),
        SwiftUI.Color(red: 0xff / 255, green: 0x4f / 255, blue: 0x58 / 255),
        SwiftUI.Color(red: 0xff / 255, green: 0xd7 / 255, blue: 0x6a / 255),
        SwiftUI.Color(red: 0x53 / 255, green: 0xe6 / 255, blue: 0xa6 / 255),
        SwiftUI.Color(red: 0x4f / 255, green: 0xa8 / 255, blue: 0xff / 255),
        SwiftUI.Color(red: 0x8b / 255, green: 0x6b / 255, blue: 0xff / 255),
    ]
}
