import DesignScaffold
import SwiftUI

/// One track's header: name plus whichever state controls the track declares. A trailing
/// slot carries anything app-specific (the spec's source-patch picker, for instance) so the
/// scaffold never has to know what routing means.
struct TimelineTrackHeader<ID: Hashable, Accessory: View>: View {
    let track: TimelineTrack<ID>
    let theme: TimelineTheme
    let onToggle: ((TimelineTrack<ID>.Control) -> Void)?
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: Tokens.Space.xs) {
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(theme.trackNameFont)
                    .foregroundStyle(theme.trackName)
                    .lineLimit(1)
                accessory
            }
            Spacer(minLength: 0)
            // Ordered by the enum, not by Set iteration — a header whose buttons move
            // between renders is unusable.
            ForEach(TimelineTrack<ID>.Control.allCases.filter(track.controls.contains), id: \.self) { control in
                Button { onToggle?(control) } label: {
                    Image(systemName: symbol(control))
                        .font(.system(size: 10, weight: .medium))
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(track.isOn(control) ? theme.controlOn : theme.controlOff)
                .help(helpText(control))
                .accessibilityLabel(Text("\(track.name) \(control.rawValue)"))
                .accessibilityAddTraits(track.isOn(control) ? .isSelected : [])
            }
        }
        .padding(.horizontal, Tokens.Space.s)
        .frame(width: theme.headerWidth, height: track.resolvedHeight, alignment: .leading)
        .background(theme.headerBackground)
        .opacity(track.isEnabled ? 1 : 0.55)
    }

    private func symbol(_ control: TimelineTrack<ID>.Control) -> String {
        switch control {
        case .lock: return track.isLocked ? "lock.fill" : "lock.open"
        case .mute: return track.isMuted ? "speaker.slash.fill" : "speaker.wave.2"
        case .solo: return "headphones"
        case .enable: return track.isEnabled ? "eye" : "eye.slash"
        }
    }

    private func helpText(_ control: TimelineTrack<ID>.Control) -> String {
        switch control {
        case .lock: return track.isLocked ? "Unlock track" : "Lock track"
        case .mute: return track.isMuted ? "Unmute" : "Mute"
        case .solo: return track.isSoloed ? "Unsolo" : "Solo"
        case .enable: return track.isEnabled ? "Disable track" : "Enable track"
        }
    }
}
