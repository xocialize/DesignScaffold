//
//  ComponentLabView.swift
//  DesignWorkspace — Component Lab
//
//  A real app that hosts every DesignScaffold component, so behaviour can be verified where
//  it actually ships rather than in a scratchpad `NSHostingView`.
//
//  The distinction is not academic. A context-menu defect reported by a consumer could not be
//  reproduced in a scratchpad harness at all — the harness and the shipping path disagreed,
//  and neither side could see both. This app closes that gap: it is an AppKit application
//  with a real window, a real responder chain, and the package consumed by LOCAL PATH, so the
//  working tree is what gets exercised.
//

import Combine
import DesignScaffold
import SwiftUI

/// One thing under test.
struct Harness: Identifiable {
    let id: String
    let title: String
    let blurb: String
    let content: () -> AnyView

    init(id: String, title: String, blurb: String, @ViewBuilder content: @escaping () -> some View) {
        self.id = id
        self.title = title
        self.blurb = blurb
        self.content = { AnyView(content()) }
    }
}

struct ComponentLabView: View {
    @ObservedObject private var log = LabLog.shared
    @State private var selected: String

    private let harnesses: [Harness] = [
        .init(id: "timeline-menu", title: "Timeline · context menus",
              blurb: "Which menu wins: one inside clipBody, or clipContextMenu? Mirrors the LTX Studio call site.") { TimelineMenuHarness() },
        .init(id: "timeline", title: "Timeline · gestures",
              blurb: "Drag, cross-track, trim, marquee, brackets, row resize.") { TimelineGestureHarness() },
        .init(id: "workspace", title: "WorkspaceSplit",
              blurb: "Which pane yields as the window narrows? Drawn frames vs the arithmetic.") { WorkspaceHarness() },
        .init(id: "chips", title: "ChipRow",
              blurb: "Single-select, wrapping. Clickability of a WRAPPED chip is unverified anywhere.") { ChipsHarness() },
        .init(id: "playlist", title: "PlaylistIterator",
              blurb: "Drag-reorder, selection, active ring.") { PlaylistHarness() },
    ]

    init() {
        _selected = State(initialValue: "timeline-menu")
    }

    var body: some View {
        // A plain HStack, deliberately, NOT `NavigationSplitView`. Measured here: a split view
        // inside a window-contentView `NSHostingView` with `sizingOptions = []` renders an
        // EMPTY window while its content still lays out — the probes reported real frames for
        // views nothing had drawn. A lab whose own chrome can lie is worse than no lab.
        HStack(spacing: 0) {
            sidebar
            Divider()
            VStack(spacing: 0) {
                if let harness = harnesses.first(where: { $0.id == selected }) {
                    ScrollView {
                        harness.content()
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(Tokens.Space.l)
                    }
                    .frame(maxHeight: .infinity)
                }
                Divider()
                logPane
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COMPONENTS").font(Tokens.Font.metricLabel)
                .foregroundStyle(Tokens.Color.tertiaryLabel)
                .padding(.horizontal, Tokens.Space.m)
                .padding(.top, Tokens.Space.m)
                .padding(.bottom, Tokens.Space.xs)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(harnesses) { harness in
                        Button {
                            selected = harness.id
                            LabLog.shared.note("HARNESS \(harness.id)")
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(harness.title).font(Tokens.Font.body.weight(.medium))
                                    .foregroundStyle(Tokens.Color.label)
                                Text(harness.blurb).font(Tokens.Font.caption)
                                    .foregroundStyle(Tokens.Color.secondaryLabel)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Tokens.Space.s)
                            .background(
                                RoundedRectangle(cornerRadius: Tokens.Radius.control)
                                    .fill(selected == harness.id
                                          ? Tokens.Color.selectionWash : .clear))
                            // ⚠️ Load-bearing. A `.plain` Button's hit region is its label's
                            // DRAWN content — the two Text lines — not the padded row a probe
                            // reports. Measured: this row's probe said y 609…657 while only
                            // 632…650 answered a click, so a driver aiming at the reported
                            // centre missed a control that looks obviously clickable.
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        // Probed like everything else a driver clicks: the sidebar is not
                        // exempt from the rule just because it is chrome.
                        .drawnFrameProbe("nav-\(harness.id)")
                    }
                }
                .padding(.horizontal, Tokens.Space.s)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 260)
        .background(Tokens.Color.surfaceElevated)
    }

    private var logPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("LOG").font(Tokens.Font.metricLabel)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                Spacer()
                Button("Clear") { log.clear() }.buttonStyle(.plain)
                    .font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.accent)
            }
            .padding(.horizontal, Tokens.Space.m)
            .padding(.vertical, Tokens.Space.xs)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(Array(log.lines.enumerated()), id: \.offset) { index, line in
                            Text(line).font(Tokens.Font.monoSmall)
                                .foregroundStyle(Tokens.Color.secondaryLabel)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, Tokens.Space.m)
                }
                .onChange(of: log.lines.count) { _, count in
                    proxy.scrollTo(count - 1, anchor: .bottom)
                }
            }
        }
        .frame(height: 180)
        .background(Tokens.Color.surfaceElevated)
    }
}
