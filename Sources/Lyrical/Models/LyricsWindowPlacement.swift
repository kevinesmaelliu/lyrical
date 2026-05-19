import AppKit
import Foundation

enum LyricsWindowPlacement: String, CaseIterable, Identifiable {
    case topLeft
    case top
    case topRight
    case left
    case center
    case right
    case bottomLeft
    case bottom
    case bottomRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topLeft: "Top Left"
        case .top: "Top"
        case .topRight: "Top Right"
        case .left: "Left"
        case .center: "Center"
        case .right: "Right"
        case .bottomLeft: "Bottom Left"
        case .bottom: "Bottom"
        case .bottomRight: "Bottom Right"
        }
    }

    var systemImage: String {
        switch self {
        case .topLeft: "arrow.up.left"
        case .top: "arrow.up"
        case .topRight: "arrow.up.right"
        case .left: "arrow.left"
        case .center: "scope"
        case .right: "arrow.right"
        case .bottomLeft: "arrow.down.left"
        case .bottom: "arrow.down"
        case .bottomRight: "arrow.down.right"
        }
    }

    func frame(size: NSSize, on screen: NSScreen? = NSScreen.main, margin: CGFloat = 20) -> NSRect {
        let visible = (screen ?? NSScreen.main)?.visibleFrame ?? .zero
        let x: CGFloat
        let y: CGFloat

        switch self {
        case .topLeft:
            x = visible.minX + margin
            y = visible.maxY - size.height - margin
        case .top:
            x = visible.midX - size.width / 2
            y = visible.maxY - size.height - margin
        case .topRight:
            x = visible.maxX - size.width - margin
            y = visible.maxY - size.height - margin
        case .left:
            x = visible.minX + margin
            y = visible.midY - size.height / 2
        case .center:
            x = visible.midX - size.width / 2
            y = visible.midY - size.height / 2
        case .right:
            x = visible.maxX - size.width - margin
            y = visible.midY - size.height / 2
        case .bottomLeft:
            x = visible.minX + margin
            y = visible.minY + margin
        case .bottom:
            x = visible.midX - size.width / 2
            y = visible.minY + margin
        case .bottomRight:
            x = visible.maxX - size.width - margin
            y = visible.minY + margin
        }

        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}

enum LyricsWindowMetrics {
    static let baseWidth: CGFloat = 320
    static let baseHeight: CGFloat = 88
    static let cornerRadius: CGFloat = 14

    static func size(widthScale: CGFloat, heightScale: CGFloat) -> NSSize {
        NSSize(width: baseWidth * widthScale, height: baseHeight * heightScale)
    }
}
