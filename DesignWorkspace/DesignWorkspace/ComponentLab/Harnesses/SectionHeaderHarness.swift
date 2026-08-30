//
//  SectionHeaderHarness.swift
//  DesignWorkspace — Component Lab
//

import DesignScaffold
import DesignScaffoldProbe
import SwiftUI

struct SectionHeaderHarness: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xl) {
            block("Default — uppercased for display, tracked 0.5") {
                SectionHeader("Provenance")
                SectionHeader("Takes", trailing: "28 kept")
                SectionHeader("Voices") {
                    Button("Add") {}.font(Tokens.Font.caption)
                        .foregroundStyle(Tokens.Color.accent).buttonStyle(.plain)
                }
            }

            block("Sentence case — MLXEngineUI's settings panels, as a theme not a fork") {
                SectionHeader("Model storage").theme(.sentenceCase)
                SectionHeader("Hugging Face access").theme(.sentenceCase)
            }

            block("⚠️ The accessibility case: VoiceOver reads the string AS WRITTEN, because the uppercasing is `.textCase`, not `.uppercased()`. Inspect these two — they look identical and do not sound identical if you build them the old way.") {
                SectionHeader("VoxCPM2 reference")
                SectionHeader("iOS export")   // Turkish locale maps `i` → `İ` under .uppercased()
            }
            Spacer(minLength: 0)
        }
        .hitTestProbe("headers")
    }

    @ViewBuilder
    private func block(_ note: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            Text(note).font(Tokens.Font.caption).foregroundStyle(Tokens.Color.tertiaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Tokens.Space.m) { content() }
                .frame(width: 320)
                .padding(Tokens.Space.m).cardSurface()
        }
    }
}
