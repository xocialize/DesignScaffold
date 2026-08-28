//
//  WorkspaceHarness.swift
//  DesignWorkspace — Component Lab
//

import Combine
import DesignScaffold
import DesignScaffoldWorkspace
import SwiftUI

/// Narrow the width slider and watch which pane yields. The reported numbers come from the
/// DRAWN frames, not from the arithmetic — the unit tests already cover the arithmetic, and
/// what is being questioned here is whether the layout honours it.
struct WorkspaceHarness: View {
    @State private var width: CGFloat = 1200

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            HStack {
                Text("width \(Int(width))").font(Tokens.Font.monoSmall)
                Slider(value: $width, in: 400...1400).frame(width: 320)
                Text(expected).font(Tokens.Font.monoSmall)
                    .foregroundStyle(Tokens.Color.secondaryLabel)
            }
            WorkspaceSplit {
                Color.blue.opacity(0.25).overlay(Text("rail").font(Tokens.Font.caption))
                    .drawnFrameProbe("pane-leading")
            } center: {
                Color.green.opacity(0.25).overlay(Text("center").font(Tokens.Font.caption))
                    .drawnFrameProbe("pane-center")
            } trailing: {
                Color.orange.opacity(0.25).overlay(Text("inspector").font(Tokens.Font.caption))
                    .drawnFrameProbe("pane-trailing")
            }
            .paneWidths(leading: 420, trailing: 360)
            .frame(width: width, height: 220)
            .border(Tokens.Color.separator)
        }
    }

    private var expected: String {
        let r = WorkspaceMetrics.resolve(available: width, leading: 420, trailing: 360,
                                         centerMinimum: 320)
        return "expected  \(Int(r.leading)) | \(Int(r.center)) | \(Int(r.trailing))"
    }
}
