import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDir = root.appendingPathComponent("assets/icon-concepts", isDirectory: true)
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let boardSize = NSSize(width: 1600, height: 1600)
let iconSize: CGFloat = 560
let image = NSImage(size: boardSize)

struct Concept {
    let label: String
    let photoCount: Int
    let rotations: [CGFloat]
    let cardShift: CGPoint
    let pivotShift: CGPoint
    let strokeWidth: CGFloat
    let checkRadius: CGFloat
    let checkOffset: CGPoint
}

let concepts = [
    Concept(
        label: "A",
        photoCount: 3,
        rotations: [-13, -4, 6],
        cardShift: CGPoint(x: -20, y: 26),
        pivotShift: CGPoint(x: 126, y: -118),
        strokeWidth: 24,
        checkRadius: 78,
        checkOffset: CGPoint(x: 142, y: -138)
    ),
    Concept(
        label: "B",
        photoCount: 3,
        rotations: [-16, -6, 4],
        cardShift: CGPoint(x: -34, y: 18),
        pivotShift: CGPoint(x: 138, y: -118),
        strokeWidth: 26,
        checkRadius: 74,
        checkOffset: CGPoint(x: 154, y: -144)
    ),
    Concept(
        label: "C",
        photoCount: 2,
        rotations: [-12, 6],
        cardShift: CGPoint(x: -12, y: 18),
        pivotShift: CGPoint(x: 122, y: -112),
        strokeWidth: 28,
        checkRadius: 82,
        checkOffset: CGPoint(x: 150, y: -140)
    ),
    Concept(
        label: "D",
        photoCount: 3,
        rotations: [-18, -7, 3],
        cardShift: CGPoint(x: -46, y: 12),
        pivotShift: CGPoint(x: 150, y: -122),
        strokeWidth: 24,
        checkRadius: 82,
        checkOffset: CGPoint(x: 164, y: -146)
    )
]

func savePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Unable to render PNG")
    }
    try png.write(to: url)
}

func roundedRectPath(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawCheck(center: CGPoint, radius: CGFloat) {
    let blue = NSColor(calibratedRed: 0.02, green: 0.42, blue: 0.92, alpha: 1)

    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(
        x: center.x - radius - 13,
        y: center.y - radius - 13,
        width: (radius + 13) * 2,
        height: (radius + 13) * 2
    )).fill()

    blue.setStroke()
    let ring = NSBezierPath(ovalIn: NSRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
    ))
    ring.lineWidth = 13
    ring.stroke()

    let check = NSBezierPath()
    check.move(to: NSPoint(x: center.x - radius * 0.46, y: center.y - radius * 0.02))
    check.line(to: NSPoint(x: center.x - radius * 0.10, y: center.y - radius * 0.36))
    check.line(to: NSPoint(x: center.x + radius * 0.54, y: center.y + radius * 0.40))
    check.lineWidth = 14
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    check.stroke()
}

func drawPhotoStack(concept: Concept, origin: CGPoint, exportSingle: Bool = false) {
    let iconRect = NSRect(x: origin.x, y: origin.y, width: iconSize, height: iconSize)
    let bg = roundedRectPath(iconRect.insetBy(dx: 24, dy: 24), radius: 86)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.10)
    shadow.shadowBlurRadius = 18
    shadow.shadowOffset = NSSize(width: 0, height: -8)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor.white.setFill()
    bg.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.setFill()
    bg.fill()
    NSColor(calibratedWhite: 0, alpha: 0.08).setStroke()
    bg.lineWidth = 2
    bg.stroke()

    let center = CGPoint(x: origin.x + iconSize / 2, y: origin.y + iconSize / 2)
    let photoSize = NSSize(width: 290, height: 238)
    let photoCornerRadius: CGFloat = 42
    let stroke = NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.11, alpha: 0.96)
    let fill = NSColor.white
    let cardBase = NSRect(
        x: center.x - photoSize.width / 2 + concept.cardShift.x,
        y: center.y - photoSize.height / 2 + concept.cardShift.y,
        width: photoSize.width,
        height: photoSize.height
    )
    let pivot = CGPoint(
        x: center.x + concept.pivotShift.x,
        y: center.y + concept.pivotShift.y
    )

    for index in 0..<concept.photoCount {
        let offset = CGPoint(
            x: CGFloat(index) * 12,
            y: CGFloat(index) * 11
        )
        let rect = NSRect(
            x: cardBase.origin.x + offset.x,
            y: cardBase.origin.y + offset.y,
            width: photoSize.width,
            height: photoSize.height
        )
        let transform = NSAffineTransform()
        transform.translateX(by: pivot.x, yBy: pivot.y)
        transform.rotate(byDegrees: concept.rotations[index])
        transform.translateX(by: -pivot.x, yBy: -pivot.y)
        transform.concat()

        let path = roundedRectPath(rect, radius: photoCornerRadius)
        fill.setFill()
        path.fill()
        stroke.setStroke()
        path.lineWidth = concept.strokeWidth
        path.stroke()

        transform.invert()
        transform.concat()
    }

    let checkCenter = CGPoint(
        x: center.x + concept.checkOffset.x,
        y: center.y + concept.checkOffset.y
    )
    drawCheck(center: checkCenter, radius: concept.checkRadius)

    if !exportSingle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 40, weight: .semibold),
            .foregroundColor: NSColor(calibratedWhite: 0.34, alpha: 1),
            .paragraphStyle: paragraph
        ]
        concept.label.draw(
            in: NSRect(x: origin.x, y: origin.y - 64, width: iconSize, height: 50),
            withAttributes: attrs
        )
    }
}

image.lockFocus()
NSColor(calibratedWhite: 0.93, alpha: 1).setFill()
NSRect(origin: .zero, size: boardSize).fill()

let positions = [
    CGPoint(x: 160, y: 900),
    CGPoint(x: 880, y: 900),
    CGPoint(x: 160, y: 190),
    CGPoint(x: 880, y: 190)
]

for (concept, position) in zip(concepts, positions) {
    drawPhotoStack(concept: concept, origin: position)
}
image.unlockFocus()

try savePNG(image, to: outputDir.appendingPathComponent("rotated-stack-board.png"))

for concept in concepts {
    let single = NSImage(size: NSSize(width: 1024, height: 1024))
    single.lockFocus()
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()
    drawPhotoStack(concept: concept, origin: CGPoint(x: 232, y: 232), exportSingle: true)
    single.unlockFocus()
    try savePNG(single, to: outputDir.appendingPathComponent("concept-\(concept.label).png"))
}

print(outputDir.appendingPathComponent("rotated-stack-board.png").path)
