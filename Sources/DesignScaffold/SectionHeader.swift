//
//  SectionHeader.swift
//  DesignScaffold
//
//  The label above a block of controls. Vocabulary, beside `cardSurface()` and `Separator`.
//

import SwiftUI

/// A small, spaced, uppercase label introducing a group of controls or content.
///
/// ```swift
/// SectionHeader("Provenance")
/// SectionHeader("Takes", trailing: "28 kept")
/// SectionHeader("Voices") { Button("Add") { … } }
/// ```
///
/// ## Promoted from twelve copies
///
/// The most-duplicated thing left on the volume after `StatusPill`: ModelSheetStudio (twice),
/// ForgeUI, Nemotron ASR, Qwen Image, Mage, MageVL, LLM Voice Chat, Liquid LFM, and three
/// separate private `sectionHeader(_:)` functions inside MLXEngineUI alone.
///
/// They agreed on the idiom — small, semibold, letter-spaced, secondary colour — and disagreed
/// on three details, settled here by majority: **tracking 0.5** (three MLXEngineUI copies and
/// Nemotron, against 0.6 in the ModelSheetStudio pair), **`secondaryLabel`**, and 11pt semibold,
/// which is `Tokens.Font.caption.weight(.semibold)`.
///
/// ## ⚠️ `textCase`, not `.uppercased()`
///
/// Every copy that uppercased did it in the string. Two problems with that, and the second is
/// the one that matters:
///
/// - `.uppercased()` with no locale uses the current one, and Turkish maps `i` to `İ`.
/// - **VoiceOver reads the transformed string.** An uppercased acronym is often spelled out
///   letter by letter, and an uppercased word loses the capitalisation that told a screen
///   reader it was a proper noun. `.textCase(.uppercase)` is a *display* transform: the
///   accessibility string stays as written.
///
/// Set `uppercases: false` on the theme for a surface that wants the title as typed —
/// MLXEngineUI's settings panels do, and they were right to.
public struct SectionHeader<Trailing: View>: View {

    private let title: String
    private let trailing: Trailing
    var themeOverride: SectionHeaderTheme?

    var theme: SectionHeaderTheme { themeOverride ?? .scaffold }

    /// A header with a trailing accessory — a count, a button, a state.
    public init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(theme.font)
                .tracking(theme.tracking)
                .textCase(theme.uppercases ? .uppercase : nil)
                .foregroundStyle(theme.color)
            Spacer(minLength: Tokens.Space.s)
            trailing
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

public extension SectionHeader where Trailing == EmptyView {
    /// Just the title.
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}

public extension SectionHeader where Trailing == Text {
    /// A title and a plain trailing string — a count, a total, a unit.
    ///
    /// Promoted from Qwen Image's copy, the only one of the twelve that had it, and the shape
    /// ML[X] Audio Studio's design needs for "Takes · 28 kept".
    init(_ title: String, trailing: String) {
        self.init(title) {
            Text(trailing)
                .font(SectionHeaderTheme.scaffold.trailingFont)
                .foregroundStyle(SectionHeaderTheme.scaffold.trailingColor)
        }
    }
}

public extension SectionHeader {
    /// Override the visual theme. Without this, ``SectionHeaderTheme/scaffold`` is used.
    func theme(_ theme: SectionHeaderTheme) -> SectionHeader {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}

/// Visual styling for a ``SectionHeader``. Initializer defaults are the token values.
public struct SectionHeaderTheme: Sendable {
    public var font: Font
    public var color: Color
    public var tracking: CGFloat
    /// Display-only uppercasing. See ``SectionHeader`` for why this is not `.uppercased()`.
    public var uppercases: Bool
    public var trailingFont: Font
    public var trailingColor: Color

    public init(
        font: Font = Tokens.Font.caption.weight(.semibold),
        color: Color = Tokens.Color.secondaryLabel,
        tracking: CGFloat = 0.5,
        uppercases: Bool = true,
        trailingFont: Font = Tokens.Font.caption,
        trailingColor: Color = Tokens.Color.tertiaryLabel
    ) {
        self.font = font
        self.color = color
        self.tracking = tracking
        self.uppercases = uppercases
        self.trailingFont = trailingFont
        self.trailingColor = trailingColor
    }
}

public extension SectionHeaderTheme {
    /// The house style, and the default.
    static let scaffold = SectionHeaderTheme()

    /// The title as typed — for settings panels and anywhere the words are prose rather than
    /// a label. MLXEngineUI's three copies did this and were right to.
    static let sentenceCase = SectionHeaderTheme(tracking: 0, uppercases: false)
}
