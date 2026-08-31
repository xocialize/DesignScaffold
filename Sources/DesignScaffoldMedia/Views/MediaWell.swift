//
//  MediaWell.swift
//  DesignScaffoldMedia
//
//  Drop a file here, or click to choose one.
//

import AppKit
import DesignScaffold
import SwiftUI
import UniformTypeIdentifiers

/// A drop target that also opens a file panel when clicked, and shows what it is holding.
///
/// ```swift
/// MediaWell("Drop an image, or click to choose", isEmpty: image == nil) { urls in
///     load(urls[0])
/// } content: {
///     Image(nsImage: image!).resizable().scaledToFit()
/// }
/// ```
///
/// ## Promoted from six copies
///
/// BiRefNet, Mage, Qwen Image, MageVL, Trellis2 and SenseNova-U1.5 each built this. They
/// agreed on the shape and disagreed on height, symbol, prompt wording, and whether a
/// drag-over state was drawn at all — half drew none, so dragging over those wells gave no
/// feedback until you let go.
///
/// ## What is actually wrong with the six, measured rather than read
///
/// They wrote **four different decoders** between them. I first claimed one of them —
/// Qwen Image's `URL(string:)` on the `.fileURL` data representation — was broken on paths
/// containing spaces. **That was wrong, and measuring it is what showed so:** the `.fileURL`
/// representation is already a percent-encoded `file://` absolute string, not a raw POSIX
/// path, so `URL(string:)` is the correct API for it and a spaced path round-trips fine.
///
/// What the probe did turn up is smaller and duller: Mage's `loadItem(forTypeIdentifier:)`
/// is **deprecated as of macOS 27**, in favour of the `loadObject(ofClass:)` that two of the
/// others already use.
///
/// The real, verified gaps are elsewhere:
///
/// - ⚠️ **None of the six validated the drop.** Whatever was dropped went straight to the
///   loader; a `.txt` on an image well returns nil, falls through a bare `else { return }`,
///   and **nothing happens at all** — no image, no message, no sign the app noticed.
/// - ⚠️ **`NSOpenPanel.allowedContentTypes` is an affordance, not a guarantee.** Measured in
///   the Component Lab: a panel restricted to `[.audio]` still returned a PNG, because
///   ⌘⇧G (Go to Folder) with an explicit path bypasses the type filter and enables Open.
///   Every copy trusted the panel for the browse path and checked nothing on the drop path,
///   so all six would have handed that PNG to an audio loader. `MediaWell` routes **both**
///   paths through the same gate, which is why this was caught at all.
/// - **Half drew no drag-over state**, so a drag over those wells gave no feedback until it
///   was released.
///
/// This uses `.dropDestination(for: URL.self)`, which removes the decode question rather
/// than answering it a fifth time — the platform hands over decoded URLs. Validation and the
/// targeted state come with it.
///
/// ## What the host still owns
///
/// Rendering the content, and loading the file. `onPick` hands over URLs; what a decoded
/// image, audio clip or mesh becomes is the app's business.
public struct MediaWell<Content: View>: View {

    private let prompt: String
    private let systemImage: String
    private let isEmpty: Bool
    private let contentTypes: [UTType]
    private let allowsMultiple: Bool
    private let onPick: ([URL]) -> Void
    private let onReject: (([URL]) -> Void)?
    private let content: Content
    var themeOverride: MediaWellTheme?

    @State private var isTargeted = false

    var theme: MediaWellTheme { themeOverride ?? .scaffold }

    public init(_ prompt: String,
                systemImage: String = "photo.on.rectangle.angled",
                isEmpty: Bool,
                allowing contentTypes: [UTType] = [.image],
                allowsMultiple: Bool = false,
                onPick: @escaping ([URL]) -> Void,
                onReject: (([URL]) -> Void)? = nil,
                @ViewBuilder content: () -> Content) {
        self.prompt = prompt
        self.systemImage = systemImage
        self.isEmpty = isEmpty
        self.contentTypes = contentTypes
        self.allowsMultiple = allowsMultiple
        self.onPick = onPick
        self.onReject = onReject
        self.content = content()
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(isTargeted ? theme.targetedFill : theme.fill)
            if isEmpty { placeholder } else { content }
        }
        .frame(height: theme.height)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .strokeBorder(isTargeted ? theme.targetedBorder : theme.border,
                              lineWidth: isTargeted ? theme.targetedBorderWidth : theme.borderWidth))
        // The whole well is the target, including the gap between the icon and the border —
        // without this, only the drawn glyph and text take a click.
        .contentShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        .onTapGesture { browse() }
        // ⚠️ `.dropDestination`, NOT `onDrop` + NSItemProvider. See the type doc: the six
        // copies wrote four decoders between them and one was broken on paths with spaces.
        .dropDestination(for: URL.self) { urls, _ in
            deliver(urls)
        } isTargeted: { targeted in
            isTargeted = targeted
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(prompt))
        .accessibilityAddTraits(.isButton)
    }

    private var placeholder: some View {
        VStack(spacing: theme.spacing) {
            Image(systemName: systemImage)
                .font(.system(size: theme.symbolSize))
                .foregroundStyle(theme.symbolColor)
            Text(prompt)
                .font(theme.promptFont)
                .foregroundStyle(theme.promptColor)
                .multilineTextAlignment(.center)
        }
        .padding(Tokens.Space.s)
        // Decorative: the well already carries `prompt` as its accessibility label, and
        // reading it twice is how a screen reader turns one control into two.
        .accessibilityHidden(true)
    }

    @discardableResult
    private func deliver(_ urls: [URL]) -> Bool {
        let (accepted, rejected) = MediaAcceptance.partition(urls, types: contentTypes)
        if !rejected.isEmpty { onReject?(rejected) }
        guard !accepted.isEmpty else { return false }
        onPick(allowsMultiple ? accepted : [accepted[0]])
        return true
    }

    private func browse() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = contentTypes
        panel.allowsMultipleSelection = allowsMultiple
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }
        // Through the same gate as a drop: the panel filters by type already, but routing
        // both paths through one place is what stops them drifting apart.
        deliver(panel.urls)
    }
}

// MARK: - Chainable configuration

public extension MediaWell {
    /// Override the visual theme. Without this, ``MediaWellTheme/scaffold`` is used.
    func theme(_ theme: MediaWellTheme) -> MediaWell {
        var copy = self
        copy.themeOverride = theme
        return copy
    }
}

public extension MediaWell where Content == EmptyView {
    /// A well that never shows content of its own — for hosts that render the loaded file
    /// somewhere else, as Trellis2's preview panel does.
    init(_ prompt: String,
         systemImage: String = "photo.on.rectangle.angled",
         allowing contentTypes: [UTType] = [.image],
         allowsMultiple: Bool = false,
         onPick: @escaping ([URL]) -> Void,
         onReject: (([URL]) -> Void)? = nil) {
        self.init(prompt, systemImage: systemImage, isEmpty: true,
                  allowing: contentTypes, allowsMultiple: allowsMultiple,
                  onPick: onPick, onReject: onReject) { EmptyView() }
    }
}
