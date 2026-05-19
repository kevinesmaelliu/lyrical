import AppKit

@MainActor
enum SettingsOpener {
    private static weak var controller: SettingsWindowController?

    static func configure(controller: SettingsWindowController) {
        self.controller = controller
    }

    static func open() {
        controller?.show()
    }
}
