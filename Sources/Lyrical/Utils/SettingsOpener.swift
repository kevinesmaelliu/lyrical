import AppKit

@MainActor
enum SettingsOpener {
    private static var controller: SettingsWindowController?

    static func configure(controller: SettingsWindowController) {
        self.controller = controller
    }

    static func open(viewModel: PlayerViewModel? = nil) {
        if let viewModel {
            controller?.attach(to: viewModel)
        }
        controller?.show()
    }
}
