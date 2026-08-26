import CoreGraphics
import Foundation

/// One row of the timeline. The scaffold owns the row's chrome (name, state controls,
/// height); what the row's clips *mean* is the consumer's business.
public struct TimelineTrack: Identifiable, Equatable, Sendable {

    /// Row kind — sets the default height, since a video row needs to show a filmstrip
    /// and a subtitle row needs one line of text.
    public enum Kind: Equatable, Sendable {
        case video, audio, subtitle

        /// Heights from the build spec (artboard "Timeline anatomy").
        public var defaultHeight: CGFloat {
            switch self {
            case .video: return 64
            case .audio: return 44
            case .subtitle: return 28
            }
        }
    }

    /// State controls a header may offer. Declared per track so an audio row can show
    /// mute/solo while a subtitle row shows only enable — rather than the component
    /// guessing from `kind`.
    public enum Control: String, CaseIterable, Equatable, Sendable {
        case lock, mute, solo, enable
    }

    public let id: String
    public var name: String
    public var kind: Kind
    /// Explicit row height; `nil` uses the kind's default. (T3's drag-resize writes here.)
    public var height: CGFloat?
    /// Which state controls this row's header shows.
    public var controls: Set<Control>

    public var isLocked: Bool
    public var isMuted: Bool
    public var isSoloed: Bool
    public var isEnabled: Bool

    public init(id: String, name: String, kind: Kind,
                height: CGFloat? = nil,
                controls: Set<Control> = [],
                isLocked: Bool = false, isMuted: Bool = false,
                isSoloed: Bool = false, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.kind = kind
        self.height = height
        self.controls = controls
        self.isLocked = isLocked
        self.isMuted = isMuted
        self.isSoloed = isSoloed
        self.isEnabled = isEnabled
    }

    /// The row's rendered height.
    public var resolvedHeight: CGFloat { height ?? kind.defaultHeight }

    public func isOn(_ control: Control) -> Bool {
        switch control {
        case .lock: return isLocked
        case .mute: return isMuted
        case .solo: return isSoloed
        case .enable: return isEnabled
        }
    }
}

/// A clip the timeline can place: something identifiable that occupies a time span on a
/// track. Deliberately the whole contract — the scaffold positions, sizes and (from T2)
/// moves it; the consumer draws whatever it means via a `ViewBuilder`.
public protocol TimelineClip: Identifiable {
    /// Seconds from the start of the timeline.
    var start: TimeInterval { get }
    /// Seconds.
    var duration: TimeInterval { get }
    /// Index into the timeline's `tracks`.
    var trackIndex: Int { get }
}

public extension TimelineClip {
    var end: TimeInterval { start + duration }
}
