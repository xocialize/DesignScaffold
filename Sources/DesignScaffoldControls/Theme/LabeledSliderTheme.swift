//
//  LabeledSliderTheme.swift
//  DesignScaffoldControls
//

import DesignScaffold
import SwiftUI

/// Visual styling for a ``LabeledSlider``. Initializer defaults are the token values.
///
/// ## How the defaults were settled
///
/// Seven copies, and a naive majority would have got two of these wrong — because four of
/// the seven (Liquid LFM, Mage, Gepard, and Mage's row helper) style themselves from
/// `MarqueeFont`/`MarqueeColor` or bare `.system(size:)`, which is the parallel vocabulary
/// AB-D-0042 exists to retire. Those are not votes about *this* vocabulary. Counting only
/// the copies already speaking in `Tokens` — Audio8, SenseNova, ML[X] LTX Studio, Moebius —
/// gives a different and better answer:
///
/// - **Title `caption`, not `body`.** Body wins 4–3 across all seven; caption wins 3–1 among
///   the token-native four. These rows sit in dense inspectors.
/// - **Readout `metricInline`.** Six of seven use *some* monospacing, at 10, 11 or 12pt. The
///   requirement underneath that is narrower than "monospaced": live digits must not jitter
///   as they tick. `metricInline` is 12pt with `.monospacedDigit()`, which fixes the jitter
///   while leaving letters proportional — so a unit suffix like `×` or `fps` still reads as
///   text rather than as terminal output.
public struct LabeledSliderTheme: Sendable {
    public var titleFont: Font
    public var titleColor: Color
    public var readoutFont: Font
    public var readoutColor: Color
    public var captionFont: Font
    public var captionColor: Color
    /// Between the title row, the slider, and the caption.
    public var spacing: CGFloat

    public init(
        titleFont: Font = Tokens.Font.caption,
        titleColor: Color = Tokens.Color.label,
        readoutFont: Font = Tokens.Font.metricInline,
        readoutColor: Color = Tokens.Color.secondaryLabel,
        captionFont: Font = Tokens.Font.caption,
        captionColor: Color = Tokens.Color.tertiaryLabel,
        spacing: CGFloat = Tokens.Space.xs
    ) {
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.readoutFont = readoutFont
        self.readoutColor = readoutColor
        self.captionFont = captionFont
        self.captionColor = captionColor
        self.spacing = spacing
    }
}

public extension LabeledSliderTheme {
    /// The house style, and the default.
    static let scaffold = LabeledSliderTheme()

    /// Value first: the number takes the primary colour and the title steps back.
    ///
    /// Audio8 Demo's copy did this deliberately — in a panel of sampling parameters the
    /// titles are read once and the numbers are what you are actually moving. Kept as a
    /// theme rather than as the default, because it was one of seven and the other six
    /// lead with the title.
    static let valueForward = LabeledSliderTheme(titleColor: Tokens.Color.secondaryLabel,
                                                 readoutColor: Tokens.Color.label)
}
