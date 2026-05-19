import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject {
    private static let contentSize = NSSize(width: 440, height: 560)

    private var window: NSWindow?
    private var hostingView: NSHostingView<SettingsView>?
    private weak var viewModel: PlayerViewModel?

    func attach(to viewModel: PlayerViewModel) {
        self.viewModel = viewModel
    }

    func show() {
        guard let viewModel else { return }

        if window == nil {
            let hosting = NSHostingView(rootView: SettingsView(viewModel: viewModel))
            hosting.frame = NSRect(origin: .zero, size: Self.contentSize)

            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: Self.contentSize),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.isReleasedWhenClosed = false
            window.contentView = hosting
            window.setContentSize(Self.contentSize)
            window.center()

            self.window = window
            self.hostingView = hosting
        } else {
            hostingView?.rootView = SettingsView(viewModel: viewModel)
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
