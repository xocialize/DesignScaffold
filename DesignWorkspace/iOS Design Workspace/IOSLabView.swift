//
//  IOSLabView.swift
//  iOS Design Workspace
//

import Combine
import DesignScaffold
import DesignScaffoldCalendar
import DesignScaffoldChips
import DesignScaffoldControls
import DesignScaffoldMetrics
import DesignScaffoldPicker
import DesignScaffoldPlaylist
import DesignScaffoldStageStepper
import DesignScaffoldStatus
import DesignScaffoldWaveform
import SwiftUI

struct IOSLabView: View {
    @State private var showBands = true
    @State private var measured: [String: CGFloat] = [:]
    private let kinds: [String: TapTargetKind] = [
        "slider track": .control, "chip row": .control,
        "picker list": .container, "playlist list": .container, "calendar": .container,
        "row action button": .control,
    ]

    @State private var temperature = 0.8
    @State private var steps = 20
    @State private var chip = "b"
    @State private var elapsed: TimeInterval = 0
    @State private var day: Date?
    @State private var pickedID: String?
    @State private var tracks = ["One", "Two", "Three"].map(Track.init)
    @State private var trackSel: String?
    @State private var favourites: Set<String> = ["Two"]

    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let chips = ["a", "b", "c", "d", "e"].map(Chip.init)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                    verdict
                    tierTwo
                    tierOne
                }
                .padding(Tokens.Space.m)
            }
            .background(Tokens.Color.surface)
            .navigationTitle("DesignScaffold · iOS")
            .toolbar {
                Toggle("44pt", isOn: $showBands).toggleStyle(.switch)
            }
        }
        .onReceive(tick) { _ in elapsed += 0.1 }
    }

    // MARK: The finding

    private var verdict: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            SectionHeader("Tap targets", trailing: "44pt minimum")
            Text("The dashed band is 44pt. A control drawn shorter than it is under the "
                 + "minimum comfortable hit area — measured here rather than argued from the "
                 + "token values.")
                .font(Tokens.Font.caption)
                .foregroundStyle(Tokens.Color.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(measured.keys.sorted(), id: \.self) { key in
                let reading = TapTargetReading(height: measured[key] ?? 0,
                                               kind: kinds[key] ?? .control)
                HStack {
                    Text(key).font(Tokens.Font.caption)
                    Spacer()
                    Text("\(reading.height, specifier: "%.0f")pt · \(reading.verdict)")
                        .font(Tokens.Font.metricInline)
                        .foregroundStyle(reading.kind == .container
                                         ? Tokens.Color.tertiaryLabel
                                         : (reading.height >= TapTarget.minimum
                                            ? Tokens.Color.ready : Tokens.Color.failure))
                }
            }
            if measured.isEmpty {
                Text("scroll down — measurements appear as controls render")
                    .font(Tokens.Font.monoSmall).foregroundStyle(Tokens.Color.tertiaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Tokens.Space.m)
        .cardSurface()
    }

    // MARK: Tier 2 — the products PLATFORMS.md marks unverified

    private var tierTwo: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            SectionHeader("Tier 2", trailing: "unverified on touch")

            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("LabeledSlider").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                LabeledSlider("Temperature", value: $temperature, in: 0...2)
                    .tapTargetBand("slider track", show: showBands, measured: $measured)
                LabeledSlider("Steps", value: $steps, in: 1...50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()

            VStack(alignment: .leading, spacing: Tokens.Space.m) {
                Text("ChipRow — single select").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                ChipRow(chips, selection: $chip) { $0.id.uppercased() }
                    .tapTargetBand("chip row", show: showBands, measured: $measured)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()

            VStack(alignment: .leading, spacing: Tokens.Space.m) {
                Text("SearchablePicker").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                SearchablePicker(Self.pickerItems, selected: pickedID) { pickedID = $0 }
                    .frame(height: 220)
                    .tapTargetBand("picker list", .container, show: showBands, measured: $measured)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()

            VStack(alignment: .leading, spacing: Tokens.Space.m) {
                Text("PlaylistIterator — drag-reorder is a MOUSE idiom; on touch it needs a "
                     + "long press. Try reordering.").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                PlaylistIterator(items: $tracks, selection: $trackSel,
                                 name: \.name,
                                 metadata: { [PlaylistMetadatum("id", $0.id)] }) { _ in
                    RoundedRectangle(cornerRadius: Tokens.Radius.control)
                        .fill(Tokens.Color.fillElevated)
                }
                .rowActions { track in
                    [ .toggle("Favourite", symbol: "star", isOn: favourites.contains(track.id)) {
                          if favourites.contains(track.id) { favourites.remove(track.id) }
                          else { favourites.insert(track.id) }
                      },
                      .destructive("Delete", symbol: "trash") { } ]
                }
                .tapTargetBand("playlist list", .container, show: showBands, measured: $measured)

                // ⚠️ The band cannot reach inside the list, so the BUTTON is measured on its
                // own — which is why PlaylistActionButton is public. This is the reading
                // that answers the ask's "an accessory row measures ≥44pt on iOS".
                Text("One action button, standalone — the hit area the list's column uses:")
                    .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.tertiaryLabel)
                PlaylistActionButton(.toggle("Favourite", symbol: "star", isOn: true) { })
                    .tapTargetBand("row action button", show: showBands, measured: $measured)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()

            VStack(alignment: .leading, spacing: Tokens.Space.m) {
                Text("CalendarView — day cells come off the same 24pt control height Chips "
                     + "does.").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                CalendarView(selection: $day)
                    .tapTargetBand("calendar", .container, show: showBands, measured: $measured)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()
        }
    }

    private static let pickerItems: [PickerItem<String>] = [
        .init(id: "a", name: "Ocean take 1", tags: ["ocean"]),
        .init(id: "b", name: "Ocean take 2", tags: ["ocean"]),
        .init(id: "c", name: "Forest ambience", tags: ["forest"]),
    ]

    // MARK: Tier 1 — declared portable

    private var tierOne: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            SectionHeader("Tier 1", trailing: "portable")

            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                StatusPill("Idle", status: .idle)
                StatusPill("Working", status: .working(elapsed: elapsed))
                StatusPill("Offline — playing cache", status: .degraded)
                StatusPill("Ready", status: .ready)
                StatusPill("Failed", status: .failed)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()

            MetricGrid {
                MetricTile("0.31", label: "First audio", unit: "s").carded()
                MetricTile("2.41", label: "Resident", unit: "GB",
                           caption: "1 of 1 resident").carded()
                MetricTile("−22.4", label: "Peak", unit: "dBFS",
                           emphasis: Tokens.Color.working).carded()
            }

            VStack(alignment: .leading, spacing: Tokens.Space.s) {
                Text("AudioWaveform").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                AudioWaveform(peaks: Self.peaks).frame(height: 56)
                Separator(.horizontal)
                Text("StageStepper").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.tertiaryLabel)
                StageStepper(progress: Self.progress)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Space.m)
            .cardSurface()
        }
    }

    private static let peaks: [Float] = (0..<120).map {
        Float(abs(sin(Double($0) / 7)) * (0.3 + 0.7 * abs(cos(Double($0) / 23))))
    }

    private static let progress = StageProgress(
        nodes: [StageNode(id: "load", title: "Load"),
                StageNode(id: "encode", title: "Encode"),
                StageNode(id: "decode", title: "Decode")],
        currentIndex: 1, counterText: "2 of 3")
}

private struct Chip: Identifiable { let id: String }

private struct Track: Identifiable {
    let id: String
    var name: String { id }
    init(_ id: String) { self.id = id }
}
