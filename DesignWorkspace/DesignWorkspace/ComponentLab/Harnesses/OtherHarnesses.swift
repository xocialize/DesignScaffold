//
//  OtherHarnesses.swift
//  DesignWorkspace — Component Lab
//

import Combine
import DesignScaffold
import DesignScaffoldChips
import DesignScaffoldPlaylist
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
    @State private var rows: [LabRow] = (1...5).map {
        LabRow(id: $0, name: "Clip \($0)", runtime: String(format: "00:00:%02d", $0 * 7))
    }
    @State private var selected: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("Drag to reorder; a committed order prints once per drag.")
                .font(Tokens.Font.caption).foregroundStyle(Tokens.Color.secondaryLabel)
            PlaylistIterator(items: $rows, selection: $selected, active: rows.first?.id,
                             name: { $0.name },
                             metadata: { [PlaylistMetadatum("TRT", $0.runtime)] })
                .onReorder { order in
                    LabLog.shared.note("REORDER \(order.map(\.id).map(String.init).joined(separator: ","))")
                }
                .frame(width: 420, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container))
                .cardSurface()
                .drawnFrameProbe("playlist")
        }
    }
}
