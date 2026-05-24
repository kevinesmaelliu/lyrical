import AppKit
import Combine
import SwiftUI

@MainActor
final class LyricsWindowController: NSObject {
    private var window: NSPanel?
    private var hostingView: NSHostingView<LyricsWindowView>?
    private weak var viewModel: PlayerViewModel?
    private var cancellables = Set<AnyCancellable>()

    func attach(to viewModel: PlayerViewModel) {
        self.viewModel = viewModel

        viewModel.$showLyricsWindow
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in
                if visible { self?.show() } else { self?.hide() }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest3(
            viewModel.$windowPlacement,
            viewModel.$windowWidthScale,
            viewModel.$windowHeightScale
        )
        .dropFirst()
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _, _ in
            self?.applyLayout(animated: true)
        }
        .store(in: &cancellables)

        if viewModel.showLyricsWindow {
            show()
        }
    }

    func show() {
        guard let viewModel else { return }
        if window == nil {
            let content = LyricsWindowView(viewModel: viewModel)
            let hosting = NSHostingView(rootView: content)
            hosting.wantsLayer = true
            hosting.layer?.cornerRadius = LyricsWindowMetrics.cornerRadius
            hosting.layer?.masksToBounds = true

            let panel = NSPanel(
                contentRect: .zero,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.becomesKeyOnlyIfNeeded = true
            panel.hidesOnDeactivate = false
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.level = .statusBar
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.contentView = hosting
            panel.setFrameAutosaveName("LyricalLyricsWindow")
            window = panel
            hostingView = hosting
        } else if let hostingView {
            hostingView.rootView = LyricsWindowView(viewModel: viewModel)
        }

        applyLayout(animated: false)
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func applyLayout(animated: Bool) {
        guard let viewModel, let window else { return }
        let size = LyricsWindowMetrics.size(
            widthScale: viewModel.windowWidthScale,
            heightScale: viewModel.windowHeightScale
        )
        let frame = viewModel.windowPlacement.frame(size: size)

        hostingView?.frame = NSRect(origin: .zero, size: size)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().setFrame(frame, display: true)
            }
        } else {
            window.setFrame(frame, display: true)
        }
    }
}
