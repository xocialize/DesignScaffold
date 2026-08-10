//
//  MetalPreviewView.swift
//  DesignWorkspace
//
//  The center Metal display preview: a 1:1 square that fills the largest
//  square fitting the available space and centers within it.
//

import SwiftUI
import AppKit
import DesignScaffold

/// The Metal display preview area.
///
/// The rendered content is always square (1:1). The square is sized to the
/// longest edge that still fits the available space — i.e. `min(width, height)`,
/// the largest square that fits — and centered, so it stays fully visible as the
/// window resizes.
///
/// The square hosts two components at different times: the file drop zone (which
/// provides content) and, later, the `EnhancedMetalView` render surface. For now
/// it shows the drop zone; a chosen file is handed to `AppManager`.
struct MetalPreviewView: View {

    /// Whether a file has been chosen yet. Before selection the square shows the
    /// drop zone; after, it shows the `EnhancedMetalView` render surface.
    @State private var hasContent = false

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            // The square content, centered in the available space.
            Group {
                if hasContent {
                    MetalHostView()
                } else {
                    FileDropView { url in
                        AppManager.shared().didSelectContentFile(at: url)
                        hasContent = true
                    }
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Mounts `AppManager`'s `EnhancedMetalView` in the SwiftUI hierarchy.
///
/// This wrapper is what gives the render surface a strong owner: SwiftUI retains
/// the view returned from `makeNSView` for as long as it is on screen, which in
/// turn keeps `AppManager.metalView` (a `weak` reference) alive so `renderLoop`
/// can push frames into it. The container view is always returned so the layout
/// is stable even if Metal is unavailable.
private struct MetalHostView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        guard let metal = AppManager.shared().makeMetalView() else {
            return container
        }
        container.addSubview(metal)
        NSLayoutConstraint.activate([
            metal.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            metal.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            metal.topAnchor.constraint(equalTo: container.topAnchor),
            metal.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

#Preview {
    MetalPreviewView()
        .frame(width: 800, height: 1080)
}
