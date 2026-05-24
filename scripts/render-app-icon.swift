#!/usr/bin/env swift
import AppKit

let sizes: [Int] = [16, 32, 128, 256, 512]
let outDir = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    : URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)

let sourceURL = outDir
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("AppIconSource.png")

guard FileManager.default.fileExists(atPath: sourceURL.path),
      let source = NSImage(contentsOf: sourceURL) else {
    fputs("error: App icon source not found at \(sourceURL.path)\n", stderr)
    exit(1)
}

func renderIcon(pixelSize: Int, from source: NSImage) -> NSImage {
    guard let cgImage = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        fputs("error: Could not read source image\n", stderr)
        exit(1)
    }

    let size = pixelSize
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fputs("error: Could not create bitmap context\n", stderr)
        exit(1)
    }

    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

    guard let output = context.makeImage() else {
        fputs("error: Could not render icon at \(size)px\n", stderr)
        exit(1)
    }

    return NSImage(cgImage: output, size: NSSize(width: size, height: size))
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "render-app-icon", code: 1)
    }
    try data.write(to: url)
}

try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for size in sizes {
    let image = renderIcon(pixelSize: size, from: source)
    try writePNG(image, to: outDir.appendingPathComponent("icon_\(size).png"))
    if size <= 256 {
        let retina = renderIcon(pixelSize: size * 2, from: source)
        try writePNG(retina, to: outDir.appendingPathComponent("icon_\(size)@2x.png"))
    }
}

let large = renderIcon(pixelSize: 1024, from: source)
try writePNG(large, to: outDir.appendingPathComponent("icon_512@2x.png"))
print("Wrote app icons to \(outDir.path)")
