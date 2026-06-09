import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("assets", isDirectory: true)
let basePNG = assets.appendingPathComponent("AppIcon-1024.png")
let iconset = assets.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icns = assets.appendingPathComponent("AppIcon.icns")

try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let canvas = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvas)

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawCard(rect: NSRect, rotation: CGFloat, pivot: CGPoint, strokeWidth: CGFloat) {
    let transform = NSAffineTransform()
    transform.translateX(by: pivot.x, yBy: pivot.y)
    transform.rotate(byDegrees: rotation)
    transform.translateX(by: -pivot.x, yBy: -pivot.y)
    transform.concat()

    let path = roundedRect(rect, radius: 48)
    NSColor.white.setFill()
    path.fill()
    NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.13, alpha: 0.97).setStroke()
    path.lineWidth = strokeWidth
    path.lineJoinStyle = .round
    path.stroke()

    transform.invert()
    transform.concat()
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Unable to render PNG")
    }
    try png.write(to: url)
}

image.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high

let bounds = NSRect(origin: .zero, size: canvas)
NSColor.clear.setFill()
bounds.fill()

let iconRect = bounds.insetBy(dx: 84, dy: 84)
let iconPath = roundedRect(iconRect, radius: 154)

let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.08)
shadow.shadowBlurRadius = 28
shadow.shadowOffset = NSSize(width: 0, height: -10)
NSGraphicsContext.saveGraphicsState()
shadow.set()
NSColor.white.setFill()
iconPath.fill()
NSGraphicsContext.restoreGraphicsState()

NSColor(calibratedWhite: 0.995, alpha: 1).setFill()
iconPath.fill()
NSColor(calibratedWhite: 0, alpha: 0.09).setStroke()
iconPath.lineWidth = 2
iconPath.stroke()

let cardSize = NSSize(width: 398, height: 318)
let frontRect = NSRect(x: 398, y: 330, width: cardSize.width, height: cardSize.height)
let pivot = CGPoint(x: 690, y: 344)
let strokeWidth: CGFloat = 34

drawCard(rect: frontRect.offsetBy(dx: -132, dy: 78), rotation: -18, pivot: pivot, strokeWidth: strokeWidth)
drawCard(rect: frontRect.offsetBy(dx: -74, dy: 36), rotation: -7, pivot: pivot, strokeWidth: strokeWidth)
drawCard(rect: frontRect, rotation: 2, pivot: pivot, strokeWidth: strokeWidth)

let checkCenter = CGPoint(x: 700, y: 318)
let checkRadius: CGFloat = 118

NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(
    x: checkCenter.x - checkRadius - 18,
    y: checkCenter.y - checkRadius - 18,
    width: (checkRadius + 18) * 2,
    height: (checkRadius + 18) * 2
)).fill()

let blue = NSColor(calibratedRed: 0.02, green: 0.42, blue: 0.92, alpha: 1)
blue.setStroke()
let ring = NSBezierPath(ovalIn: NSRect(
    x: checkCenter.x - checkRadius,
    y: checkCenter.y - checkRadius,
    width: checkRadius * 2,
    height: checkRadius * 2
))
ring.lineWidth = 24
ring.stroke()

let check = NSBezierPath()
check.move(to: NSPoint(x: checkCenter.x - 58, y: checkCenter.y + 2))
check.line(to: NSPoint(x: checkCenter.x - 16, y: checkCenter.y - 42))
check.line(to: NSPoint(x: checkCenter.x + 74, y: checkCenter.y + 62))
check.lineWidth = 24
check.lineCapStyle = .round
check.lineJoinStyle = .round
check.stroke()

image.unlockFocus()
try savePNG(image, to: basePNG)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, pixelSize) in sizes {
    let target = iconset.appendingPathComponent(name)
    let resize = Process()
    resize.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    resize.arguments = ["-z", "\(pixelSize)", "\(pixelSize)", basePNG.path, "--out", target.path]
    try resize.run()
    resize.waitUntilExit()

    if resize.terminationStatus != 0 {
        fatalError("Unable to render \(name)")
    }
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    fatalError("iconutil failed")
}

print("Created \(icns.path)")
