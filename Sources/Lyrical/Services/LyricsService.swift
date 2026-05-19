import Foundation

actor LyricsService {
    private var cache: [String: [LyricLine]] = [:]

    func lyrics(for track: NowPlaying) async -> [LyricLine] {
        let key = "\(track.artist)|\(track.title)"
        if let cached = cache[key] { return cached }

        guard let url = URL(string: "https://lrclib.net/api/get") else { return [] }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "track_name", value: track.title),
            URLQueryItem(name: "artist_name", value: track.artist),
            URLQueryItem(name: "album_name", value: track.album),
            URLQueryItem(name: "duration", value: String(track.durationMs / 1000)),
        ]

        guard let requestURL = components.url else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(from: requestURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            let payload = try JSONDecoder().decode(LRCLibResponse.self, from: data)

            if let synced = payload.syncedLyrics, !synced.isEmpty {
                let lines = LRCParser.parse(synced)
                if !lines.isEmpty {
                    cache[key] = lines
                    return lines
                }
            }

            if let plain = payload.plainLyrics, !plain.isEmpty {
                let lines = plain
                    .components(separatedBy: .newlines)
                    .enumerated()
                    .compactMap { idx, line -> LyricLine? in
                        let text = line.trimmingCharacters(in: .whitespaces)
                        guard !text.isEmpty else { return nil }
                        return LyricLine(id: idx, timestamp: Double(idx) * 4, text: text)
                    }
                cache[key] = lines
                return lines
            }
        } catch {
            return []
        }

        return []
    }
}

private struct LRCLibResponse: Decodable {
    let syncedLyrics: String?
    let plainLyrics: String?
}
