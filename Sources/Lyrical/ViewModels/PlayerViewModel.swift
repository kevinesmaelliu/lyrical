import AppKit
import Combine
import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var nowPlaying: NowPlaying?
    @Published var lyricLines: [LyricLine] = []
    @Published var activeLineIndex: Int?
    @Published var statusMessage: String = "Connect Spotify to begin"
    @Published var showLyricsWindow = true
    @Published var fontSize: Double = 17
    @Published var windowOpacity: Double
    @Published var windowWidthScale: Double
    @Published var windowHeightScale: Double
    @Published var contextLinesBefore: Int
    @Published var contextLinesAfter: Int
    @Published var windowPlacement: LyricsWindowPlacement
    @Published var menuBarArtwork: NSImage?

    private enum Defaults {
        static let opacity = "lyricsWindowOpacity"
        static let scale = "lyricsWindowScale"
        static let widthScale = "lyricsWindowWidthScale"
        static let heightScale = "lyricsWindowHeightScale"
        static let linesBefore = "lyricsContextLinesBefore"
        static let linesAfter = "lyricsContextLinesAfter"
        static let placement = "lyricsWindowPlacement"
    }

    let auth: SpotifyAuthService

    private let player: SpotifyPlayerService
    private let lyrics = LyricsService()
    private let artworkCache = ArtworkCache()
    private var pollTask: Task<Void, Never>?
    private var lastTrackKey: String?
    private var lastFetchedAt: Date = .distantPast
    private var localProgressOffset: TimeInterval = 0

    init(auth: SpotifyAuthService) {
        self.auth = auth
        self.player = SpotifyPlayerService(auth: auth)

        let storedOpacity = UserDefaults.standard.object(forKey: Defaults.opacity) as? Double
        self.windowOpacity = storedOpacity ?? 0.92

        let legacyScale = UserDefaults.standard.object(forKey: Defaults.scale) as? Double
        let storedWidth = UserDefaults.standard.object(forKey: Defaults.widthScale) as? Double
        let storedHeight = UserDefaults.standard.object(forKey: Defaults.heightScale) as? Double
        self.windowWidthScale = storedWidth ?? legacyScale ?? 1.0
        self.windowHeightScale = storedHeight ?? legacyScale ?? 1.0

        let storedLinesBefore = UserDefaults.standard.object(forKey: Defaults.linesBefore) as? Int
        self.contextLinesBefore = storedLinesBefore ?? 1

        let storedLinesAfter = UserDefaults.standard.object(forKey: Defaults.linesAfter) as? Int
        self.contextLinesAfter = storedLinesAfter ?? 1

        let placementRaw = UserDefaults.standard.string(forKey: Defaults.placement)
        self.windowPlacement = LyricsWindowPlacement(rawValue: placementRaw ?? "") ?? .bottom

        auth.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        auth.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] connected in
                if connected {
                    self?.startPolling()
                } else {
                    self?.stopPolling()
                    self?.nowPlaying = nil
                    self?.lyricLines = []
                    self?.activeLineIndex = nil
                    self?.menuBarArtwork = nil
                    self?.statusMessage = "Connect Spotify to begin"
                    Task { await self?.artworkCache.clear() }
                }
            }
            .store(in: &cancellables)

        $windowOpacity
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: Defaults.opacity) }
            .store(in: &cancellables)

        $windowWidthScale
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: Defaults.widthScale) }
            .store(in: &cancellables)

        $windowHeightScale
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: Defaults.heightScale) }
            .store(in: &cancellables)

        $contextLinesBefore
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: Defaults.linesBefore) }
            .store(in: &cancellables)

        $contextLinesAfter
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: Defaults.linesAfter) }
            .store(in: &cancellables)

        $windowPlacement
            .dropFirst()
            .sink { UserDefaults.standard.set($0.rawValue, forKey: Defaults.placement) }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func startPolling() {
        stopPolling()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func tick() async {
        guard auth.isAuthenticated else { return }

        do {
            guard let track = try await player.fetchNowPlaying() else {
                nowPlaying = nil
                lyricLines = []
                activeLineIndex = nil
                menuBarArtwork = nil
                statusMessage = "Play something on Spotify"
                return
            }

            let trackKey = "\(track.artist)|\(track.title)|\(track.id)"
            if trackKey != lastTrackKey {
                lastTrackKey = trackKey
                statusMessage = "Loading lyrics…"
                let fetched = await lyrics.lyrics(for: track)
                lyricLines = fetched
                statusMessage = fetched.isEmpty ? "No lyrics found for this track" : ""
                loadMenuBarArtwork(from: track.artworkURL)
            }

            nowPlaying = track
            lastFetchedAt = Date()
            localProgressOffset = track.progressSeconds

            let progress = currentProgress(for: track)
            activeLineIndex = LRCParser.activeLineIndex(in: lyricLines, at: progress)
        } catch {
            nowPlaying = nil
            lyricLines = []
            activeLineIndex = nil
            menuBarArtwork = nil
            statusMessage = error.localizedDescription
        }
    }

    private func loadMenuBarArtwork(from url: URL?) {
        guard let url else {
            menuBarArtwork = nil
            return
        }
        Task {
            let image = await artworkCache.image(for: url, size: 16)
            await MainActor.run {
                if nowPlaying?.artworkURL == url {
                    menuBarArtwork = image
                }
            }
        }
    }

    func currentProgress(for track: NowPlaying) -> TimeInterval {
        if track.isPlaying {
            let elapsed = Date().timeIntervalSince(lastFetchedAt)
            return localProgressOffset + max(0, elapsed)
        }
        return localProgressOffset
    }
}
