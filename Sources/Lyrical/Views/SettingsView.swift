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

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { viewModel.lyricsTextColor },
            set: { viewModel.setCustomTextColor($0) }
        )
    }

    var body: some View {
        ScrollView {
            Form {
            Section {
                if !isSpotifyConfigured {
                    TextField("Spotify Client ID", text: $clientID)
                        .textFieldStyle(.roundedBorder)
                    Text("Create a free app at [developer.spotify.com](https://developer.spotify.com/dashboard) and paste your Client ID here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if viewModel.auth.showConnectExplanation {
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
                    Label("Ready to connect", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Sign in with your Spotify account to show synced lyrics while you listen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Connect Spotify") {
                        viewModel.auth.requestConnect()
                    }
                }

                if let error = viewModel.auth.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Spotify")
            }

            Section {
                Text(
                    "After you connect, Lyrics Anywhere saves Spotify login tokens in the macOS Keychain so you stay signed in. Your Spotify password is never stored. Disconnect anytime to remove them."
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

                Slider(value: $viewModel.windowWidthScale, in: 0.2...2.0, step: 0.05) {
                    Text("Window width")
                }

                Slider(value: $viewModel.windowHeightScale, in: 0.2...2.5, step: 0.05) {
                    Text("Window height")
                }
            } header: {
                Text("Lyrics Window")
            } footer: {
                Text("Snap the lyrics strip to any screen edge or corner. Increase height when showing more lines.")
                    .font(.caption)
            }

            Section {
                Slider(value: $viewModel.backgroundOpacity, in: 0...1, step: 0.05) {
                    Text("Background transparency")
                }

                Slider(value: $viewModel.borderOpacity, in: 0...1, step: 0.05) {
                    Text("Border opacity")
                }
            } header: {
                Text("Background")
            } footer: {
                Text("Adjust the frosted panel and window outline.")
                    .font(.caption)
            }

            Section {
                Slider(value: $viewModel.fontSize, in: 6...48, step: 1) {
                    Text("Lyrics text size")
                }

                Slider(value: $viewModel.textOpacity, in: 0...1, step: 0.05) {
                    Text("Text opacity")
                }

                Toggle("Use system text color", isOn: $viewModel.useSystemTextColor)

                ColorPicker(
                    "Text color",
                    selection: textColorBinding,
                    supportsOpacity: false
                )
                .disabled(viewModel.useSystemTextColor)
            } header: {
                Text("Lyrics text")
            } footer: {
                Text("System color follows light and dark mode. Custom color applies to all lyric lines.")
                    .font(.caption)
            }
            }
            .formStyle(.grouped)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
