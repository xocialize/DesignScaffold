import DesignScaffold
import SwiftUI

/// Visual styling for a ``CalendarView``.
///
/// The default theme is ``scaffold`` — every colour, metric, and font resolved through
/// `Tokens`. The initialiser's metric and font defaults are the token values too, so a
/// custom theme that only overrides colours still inherits the scaffold geometry.
///
/// PROVENANCE: this component began as SwiftCalendarKit, a port of vanilla-calendar-pro,
/// and its theme kept that web look. Folding it into the scaffold, the tokens won where
/// the two disagreed (the original values, for the record):
///
///     cell radius   8  → Tokens.Radius.control (6)         the kit's control radius
///     cell min size 34 → Tokens.Layout.controlHeight (24)  standard control height
///     title font    .headline.semibold → Tokens.Font.sectionTitle (13 semibold)
///     day font      .callout → Tokens.Font.body (13; the cell adds monospaced digits)
///     outside-month secondary@0.5  → Tokens.Color.tertiaryLabel
///     disabled      secondary@0.35 → Tokens.Color.quaternaryLabel
///     week numbers  secondary@0.6  → Tokens.Color.tertiaryLabel
///
/// The mapping reads the tokens directly, so a token refresh from Figma re-skins the
/// calendar with no change here. The fixed `.light`/`.dark` palettes did not survive the
/// fold-in: they were hardcoded web colours, and forcing an appearance is the host's job
/// (`.preferredColorScheme`) — the semantic tokens resolve correctly under either.
public struct CalendarTheme: Sendable {

    // Colours
    public var accent: Color
    public var background: Color
    public var dayText: Color
    public var selectedDayText: Color
    public var weekendText: Color
    public var outsideMonthText: Color
    public var disabledText: Color
    public var inRangeBackground: Color
    public var todayIndicator: Color
    public var headerText: Color
    public var weekdaySymbolText: Color
    public var weekNumberText: Color

    // Metrics
    public var cellCornerRadius: CGFloat
    public var cellSpacing: CGFloat
    public var cellMinSize: CGFloat

    // Fonts
    public var titleFont: Font
    public var dayFont: Font
    public var weekdaySymbolFont: Font

    public init(
        accent: Color = Tokens.Color.accent,
        background: Color = .clear,
        dayText: Color = Tokens.Color.label,
        selectedDayText: Color = .white,
        weekendText: Color = Tokens.Color.secondaryLabel,
        outsideMonthText: Color = Tokens.Color.tertiaryLabel,
        disabledText: Color = Tokens.Color.quaternaryLabel,
        inRangeBackground: Color = Tokens.Color.accent.opacity(0.15),
        todayIndicator: Color = Tokens.Color.accent,
        headerText: Color = Tokens.Color.label,
        weekdaySymbolText: Color = Tokens.Color.secondaryLabel,
        weekNumberText: Color = Tokens.Color.tertiaryLabel,
        cellCornerRadius: CGFloat = Tokens.Radius.control,
        cellSpacing: CGFloat = Tokens.Space.xs,
        cellMinSize: CGFloat = Tokens.Layout.controlHeight,
        titleFont: Font = Tokens.Font.sectionTitle,
        dayFont: Font = Tokens.Font.body,
        weekdaySymbolFont: Font = Tokens.Font.caption.weight(.semibold)
    ) {
        self.accent = accent
        self.background = background
        self.dayText = dayText
        self.selectedDayText = selectedDayText
        self.weekendText = weekendText
        self.outsideMonthText = outsideMonthText
        self.disabledText = disabledText
        self.inRangeBackground = inRangeBackground
        self.todayIndicator = todayIndicator
        self.headerText = headerText
        self.weekdaySymbolText = weekdaySymbolText
        self.weekNumberText = weekNumberText
        self.cellCornerRadius = cellCornerRadius
        self.cellSpacing = cellSpacing
        self.cellMinSize = cellMinSize
        self.titleFont = titleFont
        self.dayFont = dayFont
        self.weekdaySymbolFont = weekdaySymbolFont
    }
}

public extension CalendarTheme {

    /// The house style, and the default — every slot resolved through `Tokens`.
    ///
    /// Notes on the two non-token slots: `background` is clear because the calendar sits
    /// on whatever surface hosts it (pair with `cardSurface()`); `selectedDayText` is
    /// white-on-accent, the system selection treatment.
    static var scaffold: CalendarTheme { CalendarTheme() }
}
