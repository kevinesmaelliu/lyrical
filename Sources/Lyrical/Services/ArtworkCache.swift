import AppKit
import Foundation

actor ArtworkCache {
    private var cache: [URL: NSImage] = [:]

    func image(for url: URL, size: CGFloat = 36) async -> NSImage? {
        if let cached = cache[url] { return cached }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let original = NSImage(data: data) else { return nil }
            let scaled = Self.scaledImage(original, side: size)
            cache[url] = scaled
            return scaled
        } catch {
            return nil
        }
    }

    func clear() {
        cache.removeAll()
    }

    private static func scaledImage(_ image: NSImage, side: CGFloat) -> NSImage {
        let target = NSSize(width: side, height: side)
        let scaled = NSImage(size: target)
        scaled.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: target),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1
        )
        scaled.unlockFocus()
        scaled.size = target
        return scaled
    }
}
