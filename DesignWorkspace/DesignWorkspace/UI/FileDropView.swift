//
//  FileDropView.swift
//  DesignWorkspace
//
//  A drop zone for providing content to the Metal display preview. Supports
//  drag-and-drop from Finder and a "Choose File…" picker.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import DesignScaffold

/// The file upload / drop zone shown in the center preview square.
///
/// Reports the chosen file through `onFileSelected`; it does no loading or
/// processing itself. Accepts a single file via drag-and-drop or the picker.
struct FileDropView: View {

    /// Called with the URL of the file the user chose or dropped.
    var onFileSelected: (URL) -> Void

    /// Content types the drop zone accepts. Defaults to images or videos dropped
    /// content becomes a texture for the Metal zone directly for images and videos
    /// after processed through a video player.
    ///
    /// Use `.movie` rather than `.video`: `.video` only represents raw video
    /// streams without audio, so common files like `.mp4`/`.mov` (which conform
    /// to `.movie`) would be greyed out in the picker.
    var allowedContentTypes: [UTType] = [.image, .movie]

    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: Tokens.Space.m) {
            Image(systemName: Tokens.Symbol.upload)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Tokens.Color.secondaryLabel)

            Text("Drop a file here")
                .font(Tokens.Font.sectionTitle)
                .foregroundStyle(Tokens.Color.label)

            Text("or")
                .font(Tokens.Font.caption)
                .foregroundStyle(Tokens.Color.tertiaryLabel)

            Button("Choose File…", action: browse)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Color.surface)
        .overlay {
            // Dashed border; highlights with the accent color while a drag is over it.
            RoundedRectangle(cornerRadius: Tokens.Radius.container)
                .strokeBorder(
                    isTargeted ? Tokens.Color.accent : Tokens.Color.separator,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.container))
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            onFileSelected(url)
            return true
        } isTargeted: { isTargeted = $0 }
    }

    /// Present a standard open panel and report the chosen file.
    private func browse() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = allowedContentTypes
        if panel.runModal() == .OK, let url = panel.url {
            onFileSelected(url)
        }
    }
}

#Preview {
    FileDropView { url in print("selected:", url) }
        .frame(width: 400, height: 400)
        .padding()
}
