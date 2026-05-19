import Foundation

struct NowPlaying: Equatable, Sendable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let artworkURL: URL?
    let durationMs: Int
    let progressMs: Int
    let isPlaying: Bool

    var durationSeconds: Double { Double(durationMs) / 1000 }
    var progressSeconds: Double { Double(progressMs) / 1000 }
}

struct LyricLine: Identifiable, Equatable, Sendable {
    let id: Int
    let timestamp: TimeInterval
    let text: String
}
