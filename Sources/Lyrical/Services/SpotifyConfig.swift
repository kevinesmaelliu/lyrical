import Foundation

enum SpotifyConfig {
    /// Set your Spotify Client ID from https://developer.spotify.com/dashboard
    /// Add redirect URI: lyrical://spotify-callback
    static var clientID: String {
        if let env = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"], !env.isEmpty {
            return env
        }
        if let bundled = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_ID") as? String,
           !bundled.isEmpty,
           !bundled.contains("$(") {
            return bundled
        }
        if let stored = UserDefaults.standard.string(forKey: "spotifyClientID"), !stored.isEmpty {
            return stored
        }
        return ""
    }

    static let redirectURI = "lyrical://spotify-callback"
    static let scopes = [
        "user-read-currently-playing",
        "user-read-playback-state",
    ].joined(separator: " ")

    static var isConfigured: Bool { !clientID.isEmpty }
}
