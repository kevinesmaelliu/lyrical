import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: PlayerViewModel?
    var lyricsWindow: LyricsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        NSApp.activate(ignoringOtherApps: true)
        Task { @MainActor in
            await viewModel?.auth.handleCallback(url)
        }
    }
}
