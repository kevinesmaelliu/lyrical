import SwiftUI

private enum MenuBarIconMetrics {
    static let pointSize: CGFloat = 16
    static let pixelSize: CGFloat = 32
}

/// Menu bar icon: album art when playing, note glyph otherwise.
struct MenuBarArtworkLabel: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        Group {
            if let artwork = viewModel.menuBarArtwork {
                Image(nsImage: artwork)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(
                        width: MenuBarIconMetrics.pointSize,
                        height: MenuBarIconMetrics.pointSize
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 12, weight: .medium))
                    .frame(
                        width: MenuBarIconMetrics.pointSize,
                        height: MenuBarIconMetrics.pointSize
                    )
            }
        }
        .frame(
            width: MenuBarIconMetrics.pointSize,
            height: MenuBarIconMetrics.pointSize,
            alignment: .center
        )
        .fixedSize()
        .accessibilityLabel(accessibilityTitle)
    }

    private var accessibilityTitle: String {
        if let track = viewModel.nowPlaying {
            return "\(track.title) by \(track.artist)"
        }
        return "Lyrical"
    }
}
