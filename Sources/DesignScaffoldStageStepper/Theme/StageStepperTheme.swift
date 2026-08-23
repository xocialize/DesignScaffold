import DesignScaffold
import SwiftUI

/// Visual styling for a ``StageStepper``.
///
/// The default theme is ``scaffold`` — resolved through `Tokens`. The initialiser's
/// defaults are the token values, so a custom theme that only overrides colours still
/// inherits the scaffold geometry.
///
/// PROVENANCE: generalised from ML[X] LTX Studio's `RunStepperView`, whose shape held
/// across ~10 measured generation runs. It already resolved everything through `Tokens`,
/// so no value needed re-basing — the two changes on the way in were removing hardcoded
/// app copy (a per-node ``StageNode/slowHint`` replaces an `id == "decode"` check) and
/// lifting the 5-second liveness delay out of the view into ``livenessDelay``.
public struct StageStepperTheme: Sendable {

    // Colours
    /// Dots, connectors, and titles for reached nodes.
    public var reached: Color
    /// Dots and connectors not yet reached.
    public var pending: Color
    public var currentTitleText: Color
    public var completeTitleText: Color
    public var upcomingTitleText: Color
    public var detailText: Color
    public var counterText: Color
    public var livenessText: Color

    // Metrics
    public var dotSize: CGFloat
    /// The ring drawn around the live node's dot; also sets the node row's height.
    public var currentRingSize: CGFloat
    public var ringLineWidth: CGFloat
    public var connectorHeight: CGFloat
    public var connectorMinLength: CGFloat
    /// One pulse cycle. The ring breathes between ``pulseMinOpacity`` and full.
    public var pulseDuration: Double
    public var pulseMinOpacity: Double
    /// Ring opacity when Reduce Motion is on — steady, never animated.
    public var reducedMotionRingOpacity: Double
    /// How long a node must be live before the elapsed timer appears.
    public var livenessDelay: TimeInterval

    // Fonts
    public var currentTitleFont: Font
    public var titleFont: Font
    public var detailFont: Font
    public var counterFont: Font
    public var livenessFont: Font

    public init(
        reached: Color = Tokens.Color.accent,
        pending: Color = Tokens.Color.separator,
        currentTitleText: Color = Tokens.Color.label,
        completeTitleText: Color = Tokens.Color.secondaryLabel,
        upcomingTitleText: Color = Tokens.Color.tertiaryLabel,
        detailText: Color = Tokens.Color.secondaryLabel,
        counterText: Color = Tokens.Color.label,
        livenessText: Color = Tokens.Color.tertiaryLabel,
        dotSize: CGFloat = 10,
        currentRingSize: CGFloat = 18,
        ringLineWidth: CGFloat = 2,
        connectorHeight: CGFloat = Tokens.Layout.hairline * 2,
        connectorMinLength: CGFloat = Tokens.Space.l,
        pulseDuration: Double = 0.9,
        pulseMinOpacity: Double = 0.15,
        reducedMotionRingOpacity: Double = 0.8,
        livenessDelay: TimeInterval = 5,
        currentTitleFont: Font = Tokens.Font.sectionTitle,
        titleFont: Font = Tokens.Font.caption,
        detailFont: Font = Tokens.Font.caption,
        counterFont: Font = Tokens.Font.monoSmall,
        livenessFont: Font = Tokens.Font.monoSmall
    ) {
        self.reached = reached
        self.pending = pending
        self.currentTitleText = currentTitleText
        self.completeTitleText = completeTitleText
        self.upcomingTitleText = upcomingTitleText
        self.detailText = detailText
        self.counterText = counterText
        self.livenessText = livenessText
        self.dotSize = dotSize
        self.currentRingSize = currentRingSize
        self.ringLineWidth = ringLineWidth
        self.connectorHeight = connectorHeight
        self.connectorMinLength = connectorMinLength
        self.pulseDuration = pulseDuration
        self.pulseMinOpacity = pulseMinOpacity
        self.reducedMotionRingOpacity = reducedMotionRingOpacity
        self.livenessDelay = livenessDelay
        self.currentTitleFont = currentTitleFont
        self.titleFont = titleFont
        self.detailFont = detailFont
        self.counterFont = counterFont
        self.livenessFont = livenessFont
    }
}

public extension StageStepperTheme {
    /// The house style, and the default — resolved through `Tokens`.
    static var scaffold: StageStepperTheme { StageStepperTheme() }
}
