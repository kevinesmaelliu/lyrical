import SwiftUI

struct SettingsView: View {
    @AppStorage("spotifyClientID") private var clientID = ""
    @ObservedObject var viewModel: PlayerViewModel

    private let placementColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    private var effectiveClientID: String {
        let trimmed = clientID.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { return trimmed }
        return SpotifyConfig.clientID
    }

    private var isSpotifyConfigured: Bool {
        !effectiveClientID.isEmpty
    }

    var body: some View {
        Form {
            Section {
                if isSpotifyConfigured {
                    Label("Ready to connect", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Sign in with your Spotify account below to show synced lyrics while you listen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    TextField("Spotify Client ID", text: $clientID)
                        .textFieldStyle(.roundedBorder)
                    Text("Create a free app at [developer.spotify.com](https://developer.spotify.com/dashboard) and paste your Client ID here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Spotify")
            }

            Section {
                if viewModel.auth.showConnectExplanation {
                    ConnectSpotifyExplanationView(
                        onContinue: { viewModel.auth.confirmConnect() },
                        onCancel: { viewModel.auth.cancelConnectExplanation() }
                    )
                    .padding(.vertical, 4)
                } else if viewModel.auth.isAuthenticated {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    if let track = viewModel.nowPlaying {
                        LabeledContent("Now playing") {
                            Text("\(track.title) — \(track.artist)")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    } else {
                        Text("Play something in Spotify to see lyrics.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Disconnect") {
                        viewModel.auth.disconnect()
                    }
                } else if viewModel.auth.isAwaitingBrowserSignIn {
                    Text("Finish signing in in your default browser, then return here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Connect Spotify") {
                        viewModel.auth.requestConnect()
                    }
                    .disabled(!isSpotifyConfigured)
                }

                if let error = viewModel.auth.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Text(
                    "After you connect, Lyrical saves Spotify login tokens in the macOS Keychain so you stay signed in. Your Spotify password is never stored. Disconnect anytime to remove them."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("Privacy & Keychain")
            }

            Section {
                LazyVGrid(columns: placementColumns, spacing: 8) {
                    ForEach(LyricsWindowPlacement.allCases) { placement in
                        PlacementButton(
                            placement: placement,
                            isSelected: viewModel.windowPlacement == placement
                        ) {
                            viewModel.windowPlacement = placement
                        }
                    }
                }
                .padding(.vertical, 4)

                Stepper(value: $viewModel.contextLinesBefore, in: 0...8) {
                    Text("Lines before current: \(viewModel.contextLinesBefore)")
                }

                Stepper(value: $viewModel.contextLinesAfter, in: 0...8) {
                    Text("Lines after current: \(viewModel.contextLinesAfter)")
                }

                Slider(value: $viewModel.windowWidthScale, in: 0.6...2.0, step: 0.05) {
                    Text("Window width")
                }

                Slider(value: $viewModel.windowHeightScale, in: 0.6...2.5, step: 0.05) {
                    Text("Window height")
                }

                Slider(value: $viewModel.windowOpacity, in: 0.25...1, step: 0.05) {
                    Text("Transparency")
                }

                Slider(value: $viewModel.fontSize, in: 12...24, step: 1) {
                    Text("Lyrics text size")
                }
            } header: {
                Text("Lyrics Window")
            } footer: {
                Text("Snap the lyrics strip to any screen edge or corner. Increase height when showing more lines.")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 640)
        .padding()
    }
}

private struct PlacementButton: View {
    let placement: LyricsWindowPlacement
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: placement.systemImage)
                    .font(.system(size: 13, weight: .medium))
                Text(placement.title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
