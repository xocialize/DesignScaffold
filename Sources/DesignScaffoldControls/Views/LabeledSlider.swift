//
//  LabeledSlider.swift
//  DesignScaffoldControls
//
//  A title, a live readout, a slider, and sometimes a line explaining what it does.
//

import DesignScaffold
import SwiftUI

/// A parameter row: the label on the left, its current value on the right, the track beneath.
///
/// ```swift
/// LabeledSlider("Temperature", value: $temperature, in: 0...2)
/// LabeledSlider("Guidance (CFG)", value: $guidance, in: 1...10, decimals: 1)
/// LabeledSlider("Max frames", value: $maxFrames, in: 64...2048, step: 32)   // Int binding
/// LabeledSlider("Speed", value: $speed, in: 0.5...2) { "\($0.formatted(.number))×" }
/// ```
///
/// ## Promoted from seven copies
///
/// Audio8 (`ParameterSlider`), SenseNova-U1.5 (`SliderRow`), ML[X] LTX Studio, Liquid LFM
/// (which had grown a second one, `intSlider`), Mage, Moebius, and Gepard (`knobSlider`).
/// They agreed on the shape — title left, value right, slider under — and the disagreements
/// were where the work was. See ``LabeledSliderTheme`` for how the visual defaults were
/// settled, and ``SliderReadout`` for the two arithmetic bugs the copies were carrying.
///
/// ## What this fixes rather than merely centralises
///
/// **Integer parameters stop being the call site's problem.** Four of the nine call sites
/// migrated in the same pass hand-wrote a `Binding<Double>` wrapper around an `Int`. Two of
/// them truncated instead of rounding, which silently loses a unit at the top of a drag.
/// The `Int` initializer below does the conversion once, correctly.
///
/// **VoiceOver gets a slider that says what it is.** Every one of the seven built the row
/// as a bare `Slider(value:in:)` with a separate `Text` beside it, so a screen reader
/// announced an unnamed "slider" and then, separately, a floating number. Here the readout
/// is the slider's `accessibilityValue` and the title is its `accessibilityLabel`, so
/// adjusting it announces "Temperature, 0.85" — and the visible readout is hidden from the
/// accessibility tree rather than read twice.
///
/// ## What the host still owns
///
/// A **tooltip** (`.help(_:)`) and a **tint** (`.tint(_:)`) are ordinary modifiers — apply
/// them to the row. There is deliberately no `help:` parameter: Audio8's copy had one and
/// wrote `.help(help ?? "")`, which attaches an empty tooltip to every row that does not
/// want one. `.controlSize(.small)` likewise belongs on the container, so a whole inspector
/// is dense with one modifier instead of every row asking.
public struct LabeledSlider: View {

    private let title: String
    private let value: Binding<Double>
    private let range: ClosedRange<Double>
    private let step: Double?
    private let caption: String?
    private let readout: (Double) -> String
    var themeOverride: LabeledSliderTheme?

    var theme: LabeledSliderTheme { themeOverride ?? .scaffold }

    private init(title: String, value: Binding<Double>, range: ClosedRange<Double>,
                 step: Double?, caption: String?, readout: @escaping (Double) -> String) {
        self.title = title
        self.value = value
        self.range = range
        self.step = step
        self.caption = caption
        self.readout = readout
    }

    // MARK: Continuous

    /// A `Double` parameter, formatted to `decimals` places with an optional unit suffix.
    public init(_ title: String, value: Binding<Double>, in range: ClosedRange<Double>,
                step: Double? = nil, decimals: Int = 2, unit: String? = nil,
                caption: String? = nil) {
        self.init(title: title, value: value, range: range, step: step, caption: caption,
                  readout: { SliderReadout.text($0, decimals: decimals, unit: unit) })
    }

    /// A `Double` parameter whose readout the host renders itself — for units the number
    /// alone cannot carry, such as `"2.5×"`, `"−6 dB"`, or a timecode.
    public init(_ title: String, value: Binding<Double>, in range: ClosedRange<Double>,
                step: Double? = nil, caption: String? = nil,
                readout: @escaping (Double) -> String) {
        self.init(title: title, value: value, range: range, step: step, caption: caption,
                  readout: readout)
    }

    // MARK: Integer

    /// An `Int` parameter — **without the call site wrapping it in a `Double` binding**.
    ///
    /// The conversion rounds and clamps (see ``SliderReadout/integer(_:in:)``). `step`
    /// defaults to 1, so the track lands on whole numbers rather than on whatever pixel the
    /// pointer stopped at.
    public init(_ title: String, value: Binding<Int>, in range: ClosedRange<Int>,
                step: Int = 1, unit: String? = nil, caption: String? = nil) {
        let bridged = Binding<Double>(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = SliderReadout.integer($0, in: range) })
        self.init(title: title,
                  value: bridged,
                  range: Double(range.lowerBound)...Double(range.upperBound),
                  step: Double(max(1, step)),
                  caption: caption,
                  readout: { SliderReadout.text($0, decimals: 0, unit: unit) })
    }

    // MARK: Body

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            HStack(spacing: Tokens.Space.s) {
                Text(title)
                    .font(theme.titleFont)
                    .foregroundStyle(theme.titleColor)
                Spacer(minLength: Tokens.Space.s)
                Text(readoutText)
                    .font(theme.readoutFont)
                    .foregroundStyle(theme.readoutColor)
                    .lineLimit(1)
                    // Read as the slider's VALUE, not as a second element floating beside it.
                    .accessibilityHidden(true)
            }
            track
                .accessibilityLabel(Text(title))
                .accessibilityValue(Text(readoutText))
            if let caption {
                Text(caption)
                    .font(theme.captionFont)
                    .foregroundStyle(theme.captionColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var readoutText: String {
        readout(SliderReadout.clamp(value.wrappedValue, to: range))
    }

    // `Slider` has no "optional step" initializer, so this branches. Safe here, and only
    // here: `step` is fixed at init and never derived from state, so this cannot change
    // shape mid-gesture — which is the way a `@ViewBuilder` `if` normally breaks a drag.
    @ViewBuilder
    private var track: some View {
        if let step {
            Slider(value: value, in: range, step: step)
        } else {
            Slider(value: value, in: range)
        }
    }
}

// MARK: - Chainable configuration

public extension LabeledSlider {
    /// Override the visual theme. Without this, ``LabeledSliderTheme/scaffold`` is used.
    func theme(_ theme: LabeledSliderTheme) -> LabeledSlider {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}
