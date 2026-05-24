import Foundation

actor SpotifyPlayerService {
    private let auth: SpotifyAuthService

    init(auth: SpotifyAuthService) {
        self.auth = auth
    }

    func fetchNowPlaying() async throws -> NowPlaying? {
        let token = try await auth.refreshTokenIfNeeded()
        return try await fetchNowPlaying(with: token)
    }

    private func fetchNowPlaying(with token: String, retryOnUnauthorized: Bool = true) async throws -> NowPlaying? {
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return nil }

        if http.statusCode == 204 { return nil }
        if http.statusCode == 401 {
            guard retryOnUnauthorized else {
                throw SpotifyError.notAuthenticated
            }
            let refreshedToken = try await auth.forceRefreshAccessToken()
            return try await fetchNowPlaying(with: refreshedToken, retryOnUnauthorized: false)
        }
        guard http.statusCode == 200 else { return nil }

        let payload = try JSONDecoder().decode(CurrentlyPlayingResponse.self, from: data)
        guard let item = payload.item else { return nil }

        let artworkURLString = item.album.images
            .sorted { ($0.width ?? 0) > ($1.width ?? 0) }
            .first?
            .url
        let artwork = artworkURLString.flatMap(URL.init(string:))

        return NowPlaying(
            id: item.id,
            title: item.name,
            artist: item.artists.map(\.name).joined(separator: ", "),
            album: item.album.name,
            artworkURL: artwork,
            durationMs: item.duration_ms,
            progressMs: payload.progress_ms ?? 0,
            isPlaying: payload.is_playing ?? false
        )
    }
}

private struct CurrentlyPlayingResponse: Decodable {
    let is_playing: Bool?
    let progress_ms: Int?
    let item: TrackItem?
}

private struct TrackItem: Decodable {
    let id: String
    let name: String
    let duration_ms: Int
    let artists: [Artist]
    let album: Album
}

private struct Artist: Decodable {
    let name: String
}

private struct Album: Decodable {
    let name: String
    let images: [ImageRef]
}

private struct ImageRef: Decodable {
    let url: String
    let width: Int?
}
