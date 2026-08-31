//  Tokens.swift
//  The shared design vocabulary. Every color, size, spacing, radius, and type
//  style used anywhere in the UI resolves through this file.
//
//  SOURCE: Figma `Demo Apps` (LGwpgABHRfxj47V8uCmkwK) — Apple's macOS 26/27 UI kit.
//  Variables read from node 9:937; the grouped-form geometry from node 0:112.
//
//  COLOR POLICY, stated because it is a judgement call and not a shortcut: the kit's label
//  and background values are EXACTLY the macOS system semantics —
//      Labels/Primary   #ffffffd9  ==  NSColor.labelColor           (white @ 85%)
//      Labels/Secondary #ffffff8c  ==  NSColor.secondaryLabelColor  (white @ 55%)
//      Window Background #1e1e1e   ==  NSColor.windowBackgroundColor (dark)
//  The kit only publishes its DARK values. Hardcoding them would pin the app to dark mode and
//  break Increase Contrast, so where a system semantic provably equals the token we use the
//  semantic and record the Figma value beside it. Only genuinely brand-specific values
//  (the accents) are carried as literals.
//
//  Everything structural — radii, control heights, insets, the type ramp — now comes from the
//  kit rather than from estimates, which is where it differed from the first pass.
//
//  RULE: no view may hardcode a color, font size, or spacing value. If a view needs a
//  value that isn't here, add it here first. That constraint is what makes the Figma
//  retrofit a one-file change instead of a hunt.

import SwiftUI

public enum Tokens {

    // MARK: - Color
    //
    // System semantic colors adapt to light/dark, increased contrast, and the user's
    // accent choice for free. A Figma retrofit replaces these with `Color(red:green:blue:)`
    // literals (or an asset catalog) under the same names.

    public enum Color {
        /// Primary reading text.
        public static let label = SwiftUI.Color.primary
        /// Supporting text: captions, units, secondary metrics.
        public static let secondaryLabel = SwiftUI.Color.secondary
        /// De-emphasized text: placeholders, disabled affordances.
        public static let tertiaryLabel = PlatformSemantics.tertiaryLabel
        /// Weakest legible text: disabled dates, watermarks. (Added for the calendar
        /// component — the kit's opacity-on-secondary stand-in maps to this semantic.)
        public static let quaternaryLabel = PlatformSemantics.quaternaryLabel

        /// Figma `Accents/Blue` #0091ff. Uses the system accent so the user's chosen accent
        /// and accessibility settings still apply — the kit value is the default-blue stand-in.
        public static let accent = SwiftUI.Color.accentColor
        /// The kit's literal blue, for surfaces that must match the design exactly.
        public static let accentFigma = SwiftUI.Color(red: 0x00 / 255, green: 0x91 / 255, blue: 0xff / 255)
        /// Hairlines and card borders.
        public static let separator = PlatformSemantics.separator

        /// The wash behind a selected row or an in-range span — the accent at low opacity.
        ///
        /// PROMOTED, not invented: the calendar's range fill and the playlist's selection
        /// fill had independently landed on exactly this value, so it lived in two places.
        /// One definition now. (MLXEngineUI's `selectionBackground` #094771 is the same
        /// intent, hardcoded — see AB-A-0019.)
        ///
        /// ⚠️ **Foreground pairing:** this is a 15% wash, NOT a solid fill — content on it
        /// keeps its normal `label`/`secondaryLabel` colours. Migrating from a solid
        /// selection colour means the hardcoded white foreground that solid fill required
        /// becomes illegible; MLXEngineUI hit exactly this. White-on-accent is correct only
        /// for a SOLID accent fill (a prominent button, a selected calendar day).
        public static let selectionWash = accent.opacity(0.15)

        /// A control fill that must read as RAISED above the surface it sits on.
        ///
        /// Derived, not borrowed: `label` at low opacity composites white-over in dark and
        /// black-over in light, so "elevated" holds in both appearances by construction.
        /// Chosen by swatch against the value it replaces (MLXEngineUI's `bgElevated`
        /// #3C3C3C) — 0.05 vanishes in light, 0.12 is heavy, and macOS has no true
        /// elevated-fill semantic: `controlColor` renders pure white in light (invisible
        /// as a fill) and `unemphasizedSelectedContentBackgroundColor` reads as a
        /// *selection*, which its name would also make a lie at the call site.
        ///
        /// ⚠️ **Foreground pairing, and the disabled-button trap.** Like `selectionWash`, this
        /// is a low-opacity fill, not a solid one — so a hardcoded `.white` label that a dark
        /// custom fill (#3C3C3C and friends) supported becomes illegible on it in LIGHT
        /// appearance. Measured in MarqueeStudio: a disabled "Select items to add" button was
        /// invisible after the swap, and looked perfect in dark.
        ///
        /// ⚠️ And do NOT reach for a de-emphasized foreground on a `.disabled()` control.
        /// `.disabled()` already dims its content; specifying `tertiaryLabel` as well dims
        /// twice and lands at roughly a third of the contrast macOS's own disabled buttons
        /// carry. Use `label` and let the modifier do it once.
        public static let fillElevated = label.opacity(0.08)

        /// Fill for an editable field or input well sitting on a surface.
        ///
        /// `textBackgroundColor` is the system semantic Apple's own bordered text fields
        /// use, so it tracks appearance and Increase Contrast. Note for conformers
        /// replacing a custom elevated well (MLXEngineUI's `bgInput` #2D2D2D): this sits
        /// *darker* in dark mode, which is the adaptation working rather than a
        /// regression. If a distinctly raised well is genuinely wanted, that is a separate
        /// `fillElevated` token — ask for it rather than reaching for a literal.
        public static let fieldFill = PlatformSemantics.fieldFill

        /// Panel/card fill that sits on top of a window material.
        public static let surface = PlatformSemantics.surface
        /// A subtler fill for nested content (metric tiles inside a card).
        public static let surfaceElevated = PlatformSemantics.surfaceElevated

        // Status — used by the engine-state pill and metric validity marks.
        public static let ready = SwiftUI.Color.green
        public static let working = SwiftUI.Color.orange
        /// Figma `Accents/Red` #ff4245.
        public static let failure = SwiftUI.Color(red: 0xff / 255, green: 0x42 / 255, blue: 0x45 / 255)
        /// Audio level in a healthy range. (The dBFS thresholds themselves are audio-domain
        /// constants, not design vocabulary — they belong to the app that measures levels.)
        public static let levelHealthy = SwiftUI.Color.green
        /// Audio level present but low.
        public static let levelLow = SwiftUI.Color.yellow
        /// Effectively silent — the failure this app exists to catch.
        public static let levelSilent = SwiftUI.Color.red
    }

    // MARK: - Typography
    //
    // Named by ROLE, not by size, so the Figma type ramp maps onto these names.
    // `.monospacedDigit()` on every numeric style is deliberate: metrics update live and
    // proportional digits make the numbers jitter, which reads as instability.

    public enum Font {
        /// Not in the kit (its window titles are a separate component); kept for the app's own
        /// screen headers and marked as such rather than pretending it is kit-derived.
        public static let screenTitle = SwiftUI.Font.system(size: 22, weight: .semibold)
        /// Figma `Body/Emphasized` — SF Pro Semibold 13 / line height 16.
        public static let sectionTitle = SwiftUI.Font.system(size: 13, weight: .semibold)
        /// Figma `Headline/Regular` — SF Pro Bold 13 / line height 16.
        public static let headline = SwiftUI.Font.system(size: 13, weight: .bold)
        /// Figma `Global/Font Size` 13.
        public static let body = SwiftUI.Font.system(size: 13)
        /// Figma `Subheadline/Regular` — SF Pro Regular 11 / line height 14.
        public static let caption = SwiftUI.Font.system(size: 11)

        /// A headline metric value (the big number on a tile).
        public static let metricValue = SwiftUI.Font.system(size: 24, weight: .medium).monospacedDigit()
        /// The unit/label under a metric value.
        public static let metricLabel = SwiftUI.Font.system(size: 10, weight: .medium)
        /// Table cells and inline numbers.
        public static let metricInline = SwiftUI.Font.system(size: 12).monospacedDigit()
        /// A panel or sheet header — one step below `screenTitle` (22), for surfaces that
        /// are a pane rather than a whole screen. Added on measured evidence: three
        /// MLXEngineUI settings headers at 520pt (AB-A-0019).
        public static let panelTitle = SwiftUI.Font.system(size: 18, weight: .semibold)

        /// Transcripts, JSON, and anything where alignment carries meaning.
        public static let mono = SwiftUI.Font.system(size: 11, design: .monospaced)
        /// Dense stat/telemetry lines one step below `mono` (the loading readout's
        /// byte counters). Pairs with `metricLabel` (10) on the size ramp.
        public static let monoSmall = SwiftUI.Font.system(size: 10, design: .monospaced)
    }

    // MARK: - Spacing (4pt base grid)

    public enum Space {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    // MARK: - Radius

    public enum Radius {
        /// Figma `Button/Radius` and `Global/Radius` = 6. Controls, chips, small buttons.
        public static let control: CGFloat = 6
        /// Figma Form Group = 12. Grouped containers and cards. (The first pass guessed 10.)
        public static let container: CGFloat = 12
        public static let large: CGFloat = 14
    }

    // MARK: - Layout

    public enum Layout {
        public static let sidebarWidth: CGFloat = 260
        public static let inspectorWidth: CGFloat = 340
        /// The inspector is resizable in an HSplitView; cap it so dragging cannot swallow
        /// the composer.
        public static let inspectorMaxWidth: CGFloat = 460
        public static let minWindowWidth: CGFloat = 1080
        public static let minWindowHeight: CGFloat = 720
        /// Sized so TWO tiles fit inside `inspectorWidth` minus padding — at 132 they did
        /// not, which is why the grid silently fell back to a wider layout.
        public static let metricTileMinWidth: CGFloat = 140
        public static let hairline: CGFloat = 1

        // Kit geometry (node 9:937 variables + node 0:112 form group).
        /// Figma `Global/Height` — standard control height.
        public static let controlHeight: CGFloat = 24
        /// Figma form row height.
        public static let rowHeight: CGFloat = 42
        /// Figma `Fields/Inset - Left|Right`.
        public static let fieldInset: CGFloat = 8
        /// Figma `Popup/Inset - Left`.
        public static let popupInset: CGFloat = 12
        /// Figma `Button/Padding - Horizontal`.
        public static let buttonPaddingHorizontal: CGFloat = 16
        /// Figma form-group horizontal padding.
        public static let groupPadding: CGFloat = 10

        /// The smallest comfortable hit area on this platform.
        ///
        /// ## ⚠️ Not a design value — a platform floor
        ///
        /// Every other number in `Layout` came from the Figma macOS kit and describes how
        /// something should LOOK. This one describes what a finger can reliably hit, and it
        /// comes from Apple's HIG rather than from the design.
        ///
        /// ⚠️ **Zero on macOS**, and that is the point: a pointer is precise, so there is no
        /// floor to impose and existing layouts must not move. The first cut of this returned
        /// `controlHeight` (24) on macOS "so nothing changes" — which was wrong, and only
        /// arithmetic caught it: chips render at **21pt**, so a 24pt floor would have grown
        /// every macOS chip row by 3pt while the comment claimed bit-identical output.
        ///
        /// On iOS it is 44. Measured in the iOS Component Lab: `ChipRow` rendered at **21pt**
        /// on a phone — under half the minimum — and `CalendarView`'s day cells take their
        /// size from `controlHeight` (24), so they were heading the same way.
        ///
        /// A component should apply this as a FLOOR (`max(designSize, minimumHitTarget)`),
        /// never as the size itself. The design value still governs appearance everywhere it
        /// is already big enough.
        public static let minimumHitTarget: CGFloat = {
            #if os(iOS)
            44
            #else
            0
            #endif
        }()
    }

    // MARK: - Motion

    /// Timings for the fleet's animated affordances.
    ///
    /// PROMOTED from ``StageStepperTheme``, which had them first and shipped with them. They
    /// moved here when a second component needed a pulse and picked its own numbers: ML[X]
    /// Audio Studio's activity pill breathes at 0.6s to 0.3 opacity against the stepper's 0.9s
    /// to 0.15. Two rhythms for the same idea — "work is in flight" — in two windows a user may
    /// have open at once, which is exactly what one vocabulary exists to prevent.
    public enum Motion {
        /// One breath, in seconds. The affordance eases between ``pulseMinOpacity`` and full.
        public static let pulseDuration: Double = 0.9
        /// How faint a pulse goes at the bottom of its cycle.
        public static let pulseMinOpacity: Double = 0.15
        /// The steady opacity a pulsing affordance holds under Reduce Motion.
        ///
        /// ⚠️ Not full opacity: the affordance still has to read as ACTIVE when it cannot
        /// breathe, and a pulse that simply stops is indistinguishable from one that finished.
        public static let reducedMotionOpacity: Double = 0.8
    }

    // MARK: - Symbols
    //
    // Centralized so the icon set is auditable in one place and swappable for exported
    // Figma assets (which must be committed as real asset bytes, never hand-drawn).

    public enum Symbol {
        public static let generate = "waveform.circle.fill"
        public static let play = "play.fill"
        public static let stop = "stop.fill"
        public static let save = "square.and.arrow.down"
        public static let voice = "person.wave.2.fill"
        public static let upload = "square.and.arrow.up"
        public static let metrics = "chart.bar.xaxis"
        public static let history = "clock.arrow.circlepath"
        public static let settings = "gearshape"
        public static let export = "arrow.up.doc"
        public static let clear = "trash"
        public static let engine = "cpu"
        public static let memory = "memorychip"
        public static let benchmark = "stopwatch"
        public static let cancel = "xmark.circle.fill"
    }
}

// MARK: - Shared view treatments

extension View {
    /// The standard card — the kit's grouped-container treatment: surface fill, hairline
    /// border, container radius (12).
    public func cardSurface() -> some View {
        self
            .background(Tokens.Color.surface,
                        in: RoundedRectangle(cornerRadius: Tokens.Radius.container))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.container)
                    .strokeBorder(Tokens.Color.separator, lineWidth: Tokens.Layout.hairline)
            )
    }
}
