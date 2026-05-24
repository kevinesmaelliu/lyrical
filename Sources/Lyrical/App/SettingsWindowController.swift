import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject {
    private static let defaultContentSize = NSSize(width: 440, height: 680)
    private static let minContentSize = NSSize(width: 360, height: 320)

    private var window: NSWindow?
    private var hostingView: NSHostingView<SettingsView>?
    private weak var viewModel: PlayerViewModel?

    func attach(to viewModel: PlayerViewModel) {
        self.viewModel = viewModel
    }

    func show() {
        guard let viewModel else { return }

        if window == nil {
            let hosting = NSHostingView(rootView: settingsRootView(viewModel))
            hosting.frame = NSRect(origin: .zero, size: Self.defaultContentSize)
            hosting.autoresizingMask = [.width, .height]

            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: Self.defaultContentSize),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.isReleasedWhenClosed = false
            window.contentView = hosting
            window.setContentSize(Self.defaultContentSize)
            window.minSize = Self.minContentSize
            window.setFrameAutosaveName("LyricalSettingsWindow")
            window.center()

            self.window = window
            self.hostingView = hosting
        } else {
            hostingView?.rootView = settingsRootView(viewModel)
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func settingsRootView(_ viewModel: PlayerViewModel) -> SettingsView {
        SettingsView(viewModel: viewModel)
    }
}
