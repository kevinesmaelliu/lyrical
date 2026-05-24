import SwiftUI

@main
struct LyricalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var auth: SpotifyAuthService
    @StateObject private var viewModel: PlayerViewModel
    @State private var didBootstrap = false

    init() {
        let auth = SpotifyAuthService()
        _auth = StateObject(wrappedValue: auth)
        _viewModel = StateObject(wrappedValue: PlayerViewModel(auth: auth))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
                .onAppear {
                    guard !didBootstrap else { return }
                    didBootstrap = true
                    bootstrap()
                }
        } label: {
            MenuBarArtworkLabel(viewModel: viewModel)
                .onAppear {
                    guard !didBootstrap else { return }
                    didBootstrap = true
                    bootstrap()
                }
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    SettingsOpener.open(viewModel: viewModel)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    @MainActor
    private func bootstrap() {
        appDelegate.viewModel = viewModel
        appDelegate.lyricsController.attach(to: viewModel)
        appDelegate.settingsController.attach(to: viewModel)
        SettingsOpener.configure(controller: appDelegate.settingsController)
        auth.restoreSessionIfNeeded()
        if auth.isAuthenticated {
            viewModel.startPolling()
        }
    }
}
