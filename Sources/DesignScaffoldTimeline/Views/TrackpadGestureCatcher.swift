import AppKit
import SwiftUI

/// Turns trackpad scroll and pinch into geometry writes.
///
/// Implemented with a **local event monitor** rather than an overlay that overrides
/// `scrollWheel(with:)`. An overlay is the obvious approach and does not work: to receive
/// scroll events a view must be the hit view, and a view that is the hit view also swallows
/// the clicks the lanes need. The monitor sees the events without touching hit testing at
/// all, and filters to this view's own window and frame so it never steals scroll from the
/// rest of the app.
///
/// Horizontal only, by request — vertical track scrolling stays with the host.
struct TrackpadGestureCatcher: NSViewRepresentable {

    /// Horizontal scroll, in points, already sign-corrected for natural scrolling.
    var onScroll: (CGFloat) -> Void
    /// Pinch magnification delta, with the cursor location in the catcher's coordinates so
    /// the zoom can stay anchored under the fingers.
    var onMagnify: (CGFloat, CGPoint) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.install(on: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onScroll = onScroll
        context.coordinator.onMagnify = onMagnify
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll, onMagnify: onMagnify)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.remove()
    }

    @MainActor
    final class Coordinator {
        var onScroll: (CGFloat) -> Void
        var onMagnify: (CGFloat, CGPoint) -> Void
        private weak var view: NSView?
        private var monitor: Any?

        init(onScroll: @escaping (CGFloat) -> Void,
             onMagnify: @escaping (CGFloat, CGPoint) -> Void) {
            self.onScroll = onScroll
            self.onMagnify = onMagnify
        }

        func install(on view: NSView) {
            self.view = view
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .magnify]) {
                [weak self] event in
                self?.handle(event) ?? event
            }
        }

        func remove() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        /// Returns nil to consume the event, or the event to let it continue.
        private func handle(_ event: NSEvent) -> NSEvent? {
            guard let view, let window = view.window, event.window === window else { return event }
            let local = view.convert(event.locationInWindow, from: nil)
            guard view.bounds.contains(local) else { return event }

            switch event.type {
            case .scrollWheel:
                // Ignore predominantly vertical scrolls: the host owns vertical.
                guard abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) else { return event }
                let delta = event.isDirectionInvertedFromDevice
                    ? event.scrollingDeltaX : -event.scrollingDeltaX
                onScroll(delta)
                return nil
            case .magnify:
                onMagnify(event.magnification, local)
                return nil
            default:
                return event
            }
        }
    }
}
