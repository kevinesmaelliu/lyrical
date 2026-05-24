import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.auth.showConnectExplanation {
                ConnectSpotifyExplanationView(
                    compact: true,
                    onContinue: { viewModel.auth.confirmConnect() },
                    onCancel: { viewModel.auth.cancelConnectExplanation() }
                )
            } else {
                mainContent
            }

            if let error = viewModel.auth.authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(width: 280)
    }

    @ViewBuilder
    private var mainContent: some View {
        if let track = viewModel.nowPlaying {
            HStack(spacing: 10) {
                ArtworkView(url: track.artworkURL)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let idx = viewModel.activeLineIndex, idx < viewModel.lyricLines.count {
                Text(viewModel.lyricLines[idx].text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } else if viewModel.auth.isAwaitingBrowserSignIn {
            Text("Finish signing in in your browser…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else if !viewModel.auth.isAuthenticated {
            Text("Connect Spotify to begin")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        Divider()

        Button(viewModel.showLyricsWindow ? "Hide Lyrics Window" : "Show Lyrics Window") {
            viewModel.showLyricsWindow.toggle()
        }

        if viewModel.auth.isAuthenticated {
            Button("Disconnect Spotify") {
                viewModel.auth.disconnect()
            }
        } else {
            Button("Connect Spotify") {
                viewModel.auth.requestConnect()
            }
        }

        Button("Settings…") {
            SettingsOpener.open(viewModel: viewModel)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Lyrics Anywhere") {
            NSApplication.shared.terminate(nil)
        }
    }
}
