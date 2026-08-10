//  LoadingCard+Previews.swift
//  Canvas gallery for the loading card. No theme calls: the scaffold look IS the default.

import DesignScaffold
import SwiftUI

private let midLoad = LoadingProgress(
    fraction: 0.29,
    status: "Streaming weights",
    fields: ["1.13 / 3.79 GB", "Tensor 193/851", "25 MB/s", "ETA 1:17"])

private let warmup = LoadingProgress(
    fraction: 0.99,
    status: "Compiling kernels · Warmup",
    fields: ["3.79 / 3.79 GB", "Tensor 851/851"])

#Preview("Plain card (no art yet)") {
    LoadingCard(progress: midLoad, title: "Audio8 TTS")
        .padding(Tokens.Space.xl)
}

#Preview("With background art, dark") {
    LoadingCard(progress: warmup, title: "Bernini R") {
        LinearGradient(colors: [SwiftUI.Color(hue: 0.62, saturation: 0.8, brightness: 0.25),
                                SwiftUI.Color(hue: 0.72, saturation: 0.6, brightness: 0.08)],
                       startPoint: .topTrailing, endPoint: .bottomLeading)
    }
    .padding(Tokens.Space.xl)
    .preferredColorScheme(.dark)
}

#Preview("As a modal over an app") {
    @Previewable @State var presented = true
    VStack {
        Text("App content").font(Tokens.Font.body)
    }
    .frame(width: 1000, height: 720)
    .loadingModal(isPresented: presented, progress: midLoad, title: "Audio8 TTS")
}

#Preview("Prism bar override, dark") {
    var t = LoadingTheme.scaffold
    t.barColors = LoadingTheme.prismBarColors
    return LoadingCard(progress: midLoad, title: "Bonsai 27B")
        .theme(t)
        .padding(Tokens.Space.xl)
        .preferredColorScheme(.dark)
}
