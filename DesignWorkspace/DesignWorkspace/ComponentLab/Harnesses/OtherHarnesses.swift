//
//  OtherHarnesses.swift
//  DesignWorkspace — Component Lab
//

import Combine
import DesignScaffold
import DesignScaffoldChips
import DesignScaffoldPlaylist
import DesignScaffoldProbe
import SwiftUI

private enum Kind: String, CaseIterable, Identifiable {
    case all = "All", generated = "Generated", imported = "Imported"
    case upscaled = "Upscaled", interpolated = "Interpolated", stabilised = "Stabilised"
    var id: Self { self }
}

/// ⚠️ The open question this exists to answer: a chip that WRAPS to a second row has never
/// been clicked, here or by any consumer. A wrapped-but-unclickable chip looks perfect in a
/// screenshot — exactly the class that has cost this library six defects.
struct ChipsHarness: View {
    @State private var wide: Kind.ID = .all
    @State private var narrow: Kind.ID = .all

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.l) {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("One row").font(Tokens.Font.caption)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
                ChipRow(Kind.allCases, selection: $wide) { $0.rawValue }
                    .padding(Tokens.Space.m).cardSurface().frame(width: 620)
                    .drawnFrameProbe("chips-wide")
                    .onChange(of: wide) { _, now in LabLog.shared.note("CHIP wide → \(now.rawValue)") }
            }
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text("Narrow — the same set WRAPPED. Click a chip on the second and third rows.")
                    .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
                ChipRow(Kind.allCases, selection: $narrow) { $0.rawValue }
                    .padding(Tokens.Space.m).cardSurface().frame(width: 240)
                    .drawnFrameProbe("chips-narrow")
                    .onChange(of: narrow) { _, now in LabLog.shared.note("CHIP narrow → \(now.rawValue)") }
            }
        }
    }
}

private struct LabRow: Identifiable, Equatable {
    let id: Int
    var name: String
    var runtime: String
}

struct PlaylistHarness: View {
    private struct Row: Identifiable {
        let id: Int
        var name: String
        var runtime: String
        var favourite = false
        var state: PlaylistRowState = .normal
    }

    @State private var rows: [Row] = [
        Row(id: 1, name: "Clip 1", runtime: "00:00:07"),
        Row(id: 2, name: "Clip 2 — portrait only", runtime: "00:00:14",
            state: .unavailable(reason: "No file for landscape")),
        Row(id: 3, name: "Clip 3", runtime: "00:00:21", favourite: true),
        Row(id: 4, name: "Clip 4 — authored skip", runtime: "00:00:28",
            state: .disabled(reason: "Skipped by the operator")),
        Row(id: 5, name: "Clip 5", runtime: "00:00:35"),
    ]
    @State private var selected: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            Text("Row 2 is UNAVAILABLE (dimmed, tooltip), row 4 is DISABLED (dimmed + struck). "
                 + "Both must still select and drag. Double-click any row → ACTIVATE, and the "
                 + "selection must NOT clear. Right-click → context menu. The trailing star "
                 + "toggles without selecting or dragging the row.")
                .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            PlaylistIterator(items: $rows, selection: $selected, active: rows.first?.id,
                             name: { $0.name },
                             metadata: { [PlaylistMetadatum("TRT", $0.runtime)] })
                .rowState { $0.state }
                .onActivate { LabLog.shared.note("ACTIVATE \($0.name)") }
                .rowContextMenu { row in
                    Button("Take \(row.name)") { LabLog.shared.note("MENU take \(row.name)") }
                    Button("Reveal") { LabLog.shared.note("MENU reveal \(row.name)") }
                }
                .rowActions { row in
                    [ .toggle("Favourite", symbol: "star", isOn: row.favourite) {
                          if let i = rows.firstIndex(where: { $0.id == row.id }) {
                              rows[i].favourite.toggle()
                              LabLog.shared.note("STAR \(row.name) → \(rows[i].favourite)")
                          }
                      },
                      .action("Export", symbol: "square.and.arrow.up") {
                          LabLog.shared.note("EXPORT \(row.name)")
                      },
                      .destructive("Delete", symbol: "trash") {
                          LabLog.shared.note("DELETE \(row.name)")
                      } ]
                }
                .onReorder { order in
                    LabLog.shared.note("REORDER \(order.map(\.id))")
                }
                .logSelection("playlist", Set(selected.map { [$0] } ?? []))
                .hitTestProbe("playlist")
                .frame(height: 380)
        }
    }
}
