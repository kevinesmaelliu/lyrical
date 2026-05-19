import SwiftUI

/// Shown before the first Spotify connect so the macOS Keychain prompt is expected.
struct ConnectSpotifyExplanationView: View {
    var compact = false
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 16) {
            Text("Connect Spotify")
                .font(compact ? .headline : .title2.weight(.semibold))

            Text("Lyrical needs permission to see what’s playing so it can sync lyrics.")
                .font(compact ? .caption : .body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if compact {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Sign in in your default browser", systemImage: "globe")
                    Label("Keychain may ask to save your session", systemImage: "key.fill")
                    Label("We never store your Spotify password", systemImage: "lock.shield")
                }
                .font(.caption)
            } else {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Sign in with Spotify in your default browser", systemImage: "globe")
                        Label("macOS may ask to save your session in Keychain", systemImage: "key.fill")
                        Label("We only store Spotify login tokens — not your password", systemImage: "lock.shield")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text(
                "If macOS shows a Keychain dialog, choose Allow. Disconnect anytime in Settings."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Continue to Spotify", action: onContinue)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(compact ? 0 : 20)
        .frame(maxWidth: compact ? 256 : 400)
    }
}
