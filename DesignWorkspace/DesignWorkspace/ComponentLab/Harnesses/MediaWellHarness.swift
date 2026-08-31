//
//  MediaWellHarness.swift
//  DesignWorkspace — Component Lab
//

import AppKit
import DesignScaffold
import DesignScaffoldMedia
import DesignScaffoldProbe
import SwiftUI
import UniformTypeIdentifiers

/// The promoted well in every state, and — the part no unit test reaches — the two paths a
/// host actually cares about: does clicking it open a panel and deliver a URL, and does a
/// drag over it say so before you let go.
struct MediaWellHarness: View {
    @State private var picked: NSImage?
    @State private var pickedName = ""
    @State private var multi: [URL] = []
    @State private var log: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.l) {
                Text("⚠️ A DRAG cannot be simulated from here — drag a file from Finder onto "
                     + "any well below to check the targeted border and the drop. Clicking a "
                     + "well opens the panel, which exercises the same delivery path.")
                    .font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .fixedSize(horizontal: false, vertical: true)

                group("Empty → filled. Click it, or drop an image.") {
                    MediaWell("Drop an image, or click to choose", isEmpty: picked == nil) { urls in
                        note("onPick \(urls.map(\.lastPathComponent))")
                        if let url = urls.first {
                            picked = NSImage(contentsOf: url); pickedName = url.lastPathComponent
                        }
                    } onReject: { urls in
                        note("onReject \(urls.map(\.lastPathComponent))")
                    } content: {
                        if let picked {
                            Image(nsImage: picked).resizable().scaledToFit().padding(Tokens.Space.xs)
                        }
                    }
                    if picked != nil {
                        HStack {
                            Text(pickedName).font(Tokens.Font.metricInline)
                                .foregroundStyle(Tokens.Color.secondaryLabel)
                            Button("Clear") { picked = nil }.controlSize(.small)
                        }
                    }
                }

                // ⚠️ The behaviour NONE of the six copies had: a well that says no. Allowing
                // only audio means an image drop must be REJECTED and reported, not silently
                // swallowed by a loader that returns nil.
                // ⚠️ This case earned its keep on first run. The panel is restricted to
                // `[.audio]`, yet ⌘⇧G with an explicit path selects a PNG and ENABLES Open —
                // `allowedContentTypes` is an affordance, not a guarantee. The well's own
                // gate refused it. Reproduce: click the well, ⌘⇧G, paste an image path.
                group("Rejection — audio only. Give it an image and watch the log.") {
                    MediaWell("Audio only", systemImage: "waveform",
                              allowing: [.audio]) { urls in
                        note("audio onPick \(urls.map(\.lastPathComponent))")
                    } onReject: { urls in
                        note("audio onReject \(urls.map(\.lastPathComponent)) ← correctly refused")
                    }
                    .theme(.compact)
                }

                group("Multiple selection") {
                    MediaWell("Drop images, or click to choose several",
                              isEmpty: multi.isEmpty, allowsMultiple: true) { urls in
                        multi = urls; note("multi onPick \(urls.count) file(s)")
                    } content: {
                        Text(multi.map(\.lastPathComponent).joined(separator: "\n"))
                            .font(Tokens.Font.monoSmall)
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                            .padding(Tokens.Space.s)
                    }
                }

                group("Themes — compact (150) · scaffold (180) · tall (260)") {
                    HStack(alignment: .top, spacing: Tokens.Space.m) {
                        MediaWell("compact") { _ in }.theme(.compact)
                        MediaWell("scaffold") { _ in }
                        MediaWell("tall") { _ in }.theme(.tall)
                    }
                }

                VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                    SectionHeader("Delivery log", trailing: "\(log.count)")
                    if log.isEmpty {
                        Text("nothing delivered yet")
                            .font(Tokens.Font.monoSmall)
                            .foregroundStyle(Tokens.Color.tertiaryLabel)
                    }
                    ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(Tokens.Font.monoSmall)
                            .foregroundStyle(Tokens.Color.secondaryLabel)
                    }
                }
            }
            .padding(Tokens.Space.m)
            .frame(maxWidth: 520, alignment: .leading)
            .hitTestProbe("media-well")
        }
    }

    private func note(_ line: String) {
        log.append(line)
        LabLog.shared.note("WELL \(line)")
    }

    @ViewBuilder
    private func group<Content: View>(_ title: String,
                                      @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            SectionHeader(title)
            content()
        }
    }
}
