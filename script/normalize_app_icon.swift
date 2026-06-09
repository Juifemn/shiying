import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: normalize_app_icon.swift input.png output.png\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let image = NSImage(contentsOf: inputURL),
      let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let cgImage = bitmap.cgImage
else {
    fputs("Unable to read icon source: \(inputURL.path)\n", stderr)
    exit(1)
}

let sourceWidth = cgImage.width
let sourceHeight = cgImage.height
let sourceSide = min(sourceWidth, sourceHeight)

// The provided source is a rendered macOS-style icon on a square screenshot.
// Crop the screenshot margin to keep the artwork, then place it on the final
// icon canvas with transparent safety padding so it matches normal Dock scale.
let cropInset = Int((Double(sourceSide) * 0.083).rounded())
let cropSide = sourceSide - cropInset * 2
let cropX = (sourceWidth - sourceSide) / 2 + cropInset
let cropY = (sourceHeight - sourceSide) / 2 + cropInset
let cropRect = CGRect(x: cropX, y: cropY, width: cropSide, height: cropSide)

guard let cropped = cgImage.cropping(to: cropRect) else {
    fputs("Unable to crop icon source\n", stderr)
    exit(1)
}

let outputSize = NSSize(width: 1024, height: 1024)
let output = NSImage(size: outputSize)
let cropImage = NSImage(cgImage: cropped, size: outputSize)

output.lockFocus()
NSColor.clear.setFill()
NSRect(origin: .zero, size: outputSize).fill()

let iconInset: CGFloat = 112
let iconRect = NSRect(origin: .zero, size: outputSize).insetBy(dx: iconInset, dy: iconInset)
let radiusScale = iconRect.width / outputSize.width
let clip = NSBezierPath(roundedRect: iconRect, xRadius: 154 * radiusScale, yRadius: 154 * radiusScale)
clip.addClip()
cropImage.draw(in: iconRect, from: NSRect(origin: .zero, size: outputSize), operation: .copy, fraction: 1)
output.unlockFocus()

guard let outputTiff = output.tiffRepresentation,
      let outputBitmap = NSBitmapImageRep(data: outputTiff),
      let png = outputBitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to write normalized icon\n", stderr)
    exit(1)
}

try png.write(to: outputURL)
