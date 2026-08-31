import DesignScaffold
import SwiftUI

/// The loading card: an 800×600 surface with an optional full-bleed background view
/// (product or model art — supply it later, the slot is ready) and the loading readout
/// anchored bottom-left — display-size percentage with a smaller % suffix, an
/// uppercase status line, dot-separated detail fields, and a thin progress bar.
///
/// ```swift
/// LoadingCard(
///     progress: LoadingProgress(fraction: 0.29,
///                               status: "Streaming weights",
///                               fields: ["1.13 / 3.79 GB", "ETA 1:17"]),
///     title: "Audio8 TTS")
/// ```
///
/// Present it over an app with ``SwiftUICore/View/loadingModal(isPresented:progress:title:theme:background:)``,
/// or embed it directly. When supplying imagery, pair the card with
/// `.preferredColorScheme(.dark)` so the semantic text resolves light over the scrim.
public struct LoadingCard<Background: View>: View {

    let progress: LoadingProgress
    let title: String?
    let background: Background
    let hasBackground: Bool
    var themeOverride: LoadingTheme?

    /// Resolved theme — the override if set, otherwise the scaffold house style.
    var theme: LoadingTheme { themeOverride ?? .scaffold }

    /// - Parameters:
    ///   - progress: What to display — fraction, status, and detail fields.
    ///   - title: Optional product/model name, top-left.
    ///   - background: Full-bleed art behind the readout, clipped to the card.
    public init(
        progress: LoadingProgress,
        title: String? = nil,
        @ViewBuilder background: () -> Background
    ) {
        self.progress = progress
        self.title = title
        self.background = background()
        self.hasBackground = true
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundLayer
            if hasBackground {
                // Legibility scrim: readout corner → clear.
                LinearGradient(
                    colors: [theme.scrim, .clear],
                    startPoint: .bottomLeading, endPoint: .topTrailing)
            }
            readout
                .padding(theme.readoutPadding)
        }
        .overlay(alignment: .topLeading) {
            if let title {
                Text(title)
                    .font(theme.titleFont)
                    .textCase(.uppercase)
                    .tracking(theme.statusTracking)
                    .foregroundStyle(theme.titleText)
                    .padding(theme.readoutPadding)
            }
        }
        .frame(width: theme.cardWidth, height: theme.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: theme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardRadius)
                .strokeBorder(theme.cardBorder, lineWidth: Tokens.Layout.hairline)
        )
        .animation(.easeOut(duration: 0.3), value: progress.fraction)
    }

    @ViewBuilder private var backgroundLayer: some View {
        if hasBackground {
            background.frame(width: theme.cardWidth, height: theme.cardHeight)
        } else {
            theme.cardSurface
        }
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            HStack(alignment: .lastTextBaseline, spacing: Tokens.Space.xs / 2) {
                Text("\(progress.percent)")
                    .font(theme.percentFont)
                    .foregroundStyle(theme.percentText)
                    // ⚠️ Progressive enhancement, gated rather than required.
                    // `.numericText(value:)` is macOS 14 / iOS 17; requiring it would have
                    // pushed the PACKAGE's iOS floor to 17 for one rolling-digit animation,
                    // and the card reads correctly without it. Below the floor the number
                    // simply changes instead of rolling.
                    .modifier(RollingDigits(value: Double(progress.percent)))
                Text(verbatim: "%")
                    .font(theme.percentSymbolFont)
                    .foregroundStyle(theme.percentSymbol)
            }

            Text(progress.status)
                .font(theme.statusFont)
                .textCase(.uppercase)
                .tracking(theme.statusTracking)
                .foregroundStyle(theme.statusText)
                .lineLimit(1)

            if let fieldsLine = progress.fieldsLine {
                Text(fieldsLine)
                    .font(theme.fieldsFont)
                    .monospacedDigit()
                    .foregroundStyle(theme.fieldsText)
                    .lineLimit(2)
            }

            bar
                .padding(.top, Tokens.Space.m)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var bar: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(theme.barTrack)
            Rectangle()
                .fill(LinearGradient(colors: theme.barColors,
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: theme.barWidth * progress.clampedFraction)
        }
        .frame(width: theme.barWidth, height: theme.barHeight)
    }

    private var accessibilityText: String {
        var parts = [String]()
        if let title { parts.append(title) }
        parts.append("loading, \(progress.percent) percent")
        parts.append(progress.status)
        if let fieldsLine = progress.fieldsLine { parts.append(fieldsLine) }
        return parts.joined(separator: ", ")
    }
}

extension LoadingCard where Background == EmptyView {
    /// A card with no art (yet) — the readout on the plain scaffold surface.
    public init(progress: LoadingProgress, title: String? = nil) {
        self.progress = progress
        self.title = title
        self.background = EmptyView()
        self.hasBackground = false
    }
}

public extension LoadingCard {
    /// Override the visual theme. Without this, ``LoadingTheme/scaffold`` is used.
    func theme(_ theme: LoadingTheme) -> LoadingCard {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}

// MARK: - Modal presentation

private struct LoadingModalModifier<Card: View>: ViewModifier {
    let isPresented: Bool
    let backdrop: Color
    let card: Card

    func body(content: Content) -> some View {
        content.overlay {
            ZStack {
                if isPresented {
                    backdrop
                        .ignoresSafeArea()
                        .transition(.opacity)
                    card
                        .transition(.scale(scale: 0.97).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: isPresented)
        }
    }
}

public extension View {

    /// Present a ``LoadingCard`` as a modal over this view: a dimmed backdrop and the
    /// centred card, animated in and out with `isPresented`. There is deliberately no
    /// close affordance — dismissal is the load's job, not the user's.
    func loadingModal<Background: View>(
        isPresented: Bool,
        progress: LoadingProgress,
        title: String? = nil,
        theme: LoadingTheme = .scaffold,
        @ViewBuilder background: () -> Background
    ) -> some View {
        modifier(LoadingModalModifier(
            isPresented: isPresented,
            backdrop: theme.backdrop,
            card: LoadingCard(progress: progress, title: title, background: background)
                .theme(theme)))
    }

    /// The art-less variant — the readout on the plain scaffold surface.
    func loadingModal(
        isPresented: Bool,
        progress: LoadingProgress,
        title: String? = nil,
        theme: LoadingTheme = .scaffold
    ) -> some View {
        modifier(LoadingModalModifier(
            isPresented: isPresented,
            backdrop: theme.backdrop,
            card: LoadingCard(progress: progress, title: title).theme(theme)))
    }
}

/// Rolls the percentage's digits where the platform can, and does nothing where it cannot.
private struct RollingDigits: ViewModifier {
    let value: Double

    func body(content: Content) -> some View {
        if #available(macOS 14, iOS 17, *) {
            content.contentTransition(.numericText(value: value))
        } else {
            content
        }
    }
}
