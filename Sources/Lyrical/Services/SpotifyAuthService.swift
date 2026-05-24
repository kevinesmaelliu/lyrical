import AppKit
import Foundation

@MainActor
final class SpotifyAuthService: ObservableObject {
    private enum Storage {
        static let sessionEnabled = "spotifySessionEnabled"
        static let keychainExplained = "spotifyKeychainExplained"
    }

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isAwaitingBrowserSignIn = false
    @Published private(set) var authError: String?
    @Published var showConnectExplanation = false

    private var codeVerifier: String?

    init() {
        // Do not touch Keychain here — avoids a surprise system dialog on launch.
    }

    /// Call once at startup when the user previously connected Spotify.
    func restoreSessionIfNeeded() {
        guard UserDefaults.standard.bool(forKey: Storage.sessionEnabled) else { return }
        isAuthenticated = KeychainHelper.read(account: .accessToken) != nil
    }

    func requestConnect() {
        authError = nil
        guard SpotifyConfig.isConfigured else {
            authError = "Add your Spotify Client ID in Settings first."
            return
        }

        if UserDefaults.standard.bool(forKey: Storage.keychainExplained) {
            connect()
        } else {
            showConnectExplanation = true
        }
    }

    func confirmConnect() {
        UserDefaults.standard.set(true, forKey: Storage.keychainExplained)
        showConnectExplanation = false
        connect()
    }

    func cancelConnectExplanation() {
        showConnectExplanation = false
    }

    func connect() {
        authError = nil
        guard SpotifyConfig.isConfigured else {
            authError = "Add your Spotify Client ID in Settings first."
            return
        }

        let verifier = PKCE.generateVerifier()
        codeVerifier = verifier
        let challenge = PKCE.challenge(for: verifier)

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: SpotifyConfig.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: SpotifyConfig.redirectURI),
            URLQueryItem(name: "scope", value: SpotifyConfig.scopes),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
        ]

        guard let authURL = components.url else { return }

        isAwaitingBrowserSignIn = true
        NSApp.activate(ignoringOtherApps: true)

        guard NSWorkspace.shared.open(authURL) else {
            isAwaitingBrowserSignIn = false
            authError = "Could not open your default browser. Try again."
            return
        }
    }

    func handleCallback(_ url: URL) async {
        isAwaitingBrowserSignIn = false

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            authError = "Spotify sign-in was cancelled or denied (\(error))."
            return
        }

        guard let code = queryItems.first(where: { $0.name == "code" })?.value,
              let verifier = codeVerifier
        else {
            authError = "Authorization failed. Try connecting again."
            return
        }

        await exchangeCode(code, verifier: verifier)
    }

    func disconnect() {
        KeychainHelper.deleteAll()
        UserDefaults.standard.set(false, forKey: Storage.sessionEnabled)
        invalidateSession()
    }

    private func invalidateSession() {
        isAuthenticated = false
        isAwaitingBrowserSignIn = false
    }

    /// Clears stored tokens when the session can no longer be used.
    func clearInvalidSession() {
        disconnect()
    }

    func accessToken() async throws -> String {
        if let token = KeychainHelper.read(account: .accessToken) {
            return token
        }
        throw SpotifyError.notAuthenticated
    }

    private func exchangeCode(_ code: String, verifier: String) async {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": SpotifyConfig.redirectURI,
            "client_id": SpotifyConfig.clientID,
            "code_verifier": verifier,
        ]
        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                authError = "Token exchange failed."
                return
            }
            let json = try JSONDecoder().decode(TokenResponse.self, from: data)
            codeVerifier = nil
            persistSession(accessToken: json.access_token, refreshToken: json.refresh_token)
        } catch {
            authError = error.localizedDescription
        }
    }

    /// Clears a stale access token and fetches a new one using the refresh token.
    func forceRefreshAccessToken() async throws -> String {
        KeychainHelper.delete(account: .accessToken)
        return try await refreshTokenIfNeeded()
    }

    func refreshTokenIfNeeded() async throws -> String {
        if let token = KeychainHelper.read(account: .accessToken) {
            return token
        }
        guard let refresh = KeychainHelper.read(account: .refreshToken) else {
            clearInvalidSession()
            throw SpotifyError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": SpotifyConfig.clientID,
        ]
        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            clearInvalidSession()
            throw SpotifyError.notAuthenticated
        }
        let json = try JSONDecoder().decode(TokenResponse.self, from: data)
        persistSession(accessToken: json.access_token, refreshToken: json.refresh_token)
        return json.access_token
    }

    private func persistSession(accessToken: String, refreshToken: String?) {
        KeychainHelper.save(accessToken, account: .accessToken)
        if let refreshToken {
            KeychainHelper.save(refreshToken, account: .refreshToken)
        }
        UserDefaults.standard.set(true, forKey: Storage.sessionEnabled)
        isAuthenticated = true
        isAwaitingBrowserSignIn = false
    }
}

enum SpotifyError: LocalizedError {
    case notAuthenticated
    case noActivePlayback

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "Connect Spotify in Settings."
        case .noActivePlayback: "Nothing is playing on Spotify."
        }
    }
}

private struct TokenResponse: Decodable {
    let access_token: String
    let refresh_token: String?
    let expires_in: Int?
}
