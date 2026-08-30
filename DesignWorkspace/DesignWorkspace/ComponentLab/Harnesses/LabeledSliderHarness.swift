//
//  LabeledSliderHarness.swift
//  DesignWorkspace — Component Lab
//

import DesignScaffold
import DesignScaffoldControls
import DesignScaffoldProbe
import SwiftUI

/// Every initializer of the promoted slider, plus the two things the model tests cannot
/// reach: that an `Int` binding really does land on whole numbers while you drag, and that
/// the readout never disagrees with the track under it.
struct LabeledSliderHarness: View {
    @State private var temperature = 0.8
    @State private var guidance = 5.0
    @State private var maxTokens = 512
    @State private var maxFrames = 640
    @State private var speed = 1.0
    @State private var uneven = 50.0
    @State private var disabled = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.l) {
                group("Double — default 2 decimals, no step") {
                    LabeledSlider("Temperature", value: $temperature, in: 0...2)
                }
                group("Double — 1 decimal, with a caption") {
                    LabeledSlider("Guidance (CFG)", value: $guidance, in: 1...10, decimals: 1,
                                  caption: "how closely the render follows the prompt")
                }
                group("Int — the call site passes an Int, not a Double binding") {
                    LabeledSlider("Max tokens", value: $maxTokens, in: 32...2048)
                    Text("bound value: \(maxTokens) — must always be a whole number, and must "
                         + "reach 2048 at the far right rather than stopping at 2047.")
                        .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.tertiaryLabel)
                }
                group("Int — stepped by 32, with a unit") {
                    LabeledSlider("Max frames", value: $maxFrames, in: 64...2048, step: 32,
                                  unit: " frames")
                    Text("bound value: \(maxFrames) — every value must be 64 + a multiple of 32.")
                        .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.tertiaryLabel)
                }
                group("Custom readout — units the number cannot carry") {
                    LabeledSlider("Speed", value: $speed, in: 0.5...2, step: 0.05) {
                        "\($0.formatted(.number.precision(.fractionLength(2))))×"
                    }
                }
                // ⚠️ This case earned its place immediately: it is what showed the readout
                // snapping to the step grid while the KNOB did not. Starting value 50 on a
                // 0…100-by-30 grid rendered the knob at 50 and the readout at 60, because
                // `Slider(value:in:step:)` snaps values it is dragged to, never one it was
                // handed. The readout now echoes the binding.
                //
                // Measured here too: when the step does not divide the range the top is
                // genuinely unreachable — dragging hard right stops at 90, not 100.
                group("Uneven step — readout must agree with the knob, untouched and dragged") {
                    LabeledSlider("Uneven", value: $uneven, in: 0...100, step: 30, decimals: 0)
                    Text("BEFORE touching it the readout must say 50, matching the knob — not "
                         + "60, the nearest grid point. Then drag hard right: it stops at 90, "
                         + "because 0…100 by 30 cannot reach 100.")
                        .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.tertiaryLabel)
                }
                group("Themes — house style vs value-forward (Audio8's choice)") {
                    LabeledSlider("Top P", value: $temperature, in: 0...1)
                    LabeledSlider("Top P", value: $temperature, in: 0...1)
                        .theme(.valueForward)
                }
                group("Disabled — one modifier dims the whole row") {
                    Toggle("disabled", isOn: $disabled).font(Tokens.Font.caption)
                    LabeledSlider("Temperature", value: $temperature, in: 0...2)
                        .disabled(disabled)
                        .help("A tooltip is the host's, applied like any modifier.")
                }
            }
            .padding(Tokens.Space.m)
            .hitTestProbe("labeled-slider")
        }
    }

    @ViewBuilder
    private func group<Content: View>(_ title: String,
                                      @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            SectionHeader(title)
            content()
        }
        .frame(maxWidth: 360, alignment: .leading)
    }
}
