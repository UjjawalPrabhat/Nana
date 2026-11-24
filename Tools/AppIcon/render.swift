// Renders Nana's three app icons from the redesign's icon tiles.
// Run from the repo root: swift Tools/AppIcon/render.swift
import AppKit
import CoreText
import ImageIO

let fontURL = URL(fileURLWithPath: "Nana/Resources/Fonts/BricolageGrotesqueCondensed-ExtraBold.ttf")
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

let size: CGFloat = 1024
let butter = NSColor(srgbRed: 1, green: 0xF3 / 255, blue: 0xD1 / 255, alpha: 1)
let cobalt = NSColor(srgbRed: 0x24 / 255, green: 0x38 / 255, blue: 0xC9 / 255, alpha: 1)
let nightInk = NSColor(srgbRed: 0x15 / 255, green: 0x18 / 255, blue: 0x43 / 255, alpha: 1)
let banana = NSColor(srgbRed: 1, green: 0xD4 / 255, blue: 0x5C / 255, alpha: 1)
let lilac = NSColor(srgbRed: 0xDC / 255, green: 0xD0 / 255, blue: 1, alpha: 1)

func render(_ name: String, background: NSColor, draw: (CGContext) -> Void) throws {
    // No alpha channel: App Store icons must be opaque.
    let context = CGContext(
        data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    context.setFillColor(background.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    draw(context)
    NSGraphicsContext.restoreGraphicsState()

    let folder = "Nana/Assets.xcassets/\(name).appiconset"
    try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
    let url = URL(fileURLWithPath: "\(folder)/\(name).png") as CFURL
    let destination = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    let contents = """
    {
      "images" : [
        {
          "filename" : "\(name).png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try contents.write(toFile: "\(folder)/Contents.json", atomically: true, encoding: .utf8)
}

/// Nana: the Butter "n" on Cobalt, cropped by the bottom edge like the "n"
/// printed on the Nana Pod. Same outline as `NanaGlyph` in the app.
try render("AppIcon", background: cobalt) { context in
    // Icon coordinates run top-down; Core Graphics runs bottom-up.
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: size - y) }
    func arch(cx: CGFloat, cy: CGFloat, a: CGFloat, b: CGFloat) -> [CGPoint] {
        (0...60).map { step in
            let t = CGFloat.pi * CGFloat(step) / 60
            let c = cos(t), s = sin(t)
            return point(cx + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / 2.4), cy - b * pow(abs(s), 2 / 2.4))
        }
    }
    func polygon(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }
    let stem = polygon([point(243, 1024), point(243, 189), point(424, 189), point(424, 1024)])
    let bridge = polygon([point(420, 1024), point(420, 467), point(475, 467), point(475, 1024)])
    let outer = polygon([point(782, 1024)] + arch(cx: 612, cy: 470, a: 170, b: 301) + [point(442, 1024)])
    let counter = polygon([point(563, 1100)] + arch(cx: 512, cy: 560, a: 51, b: 166) + [point(461, 1100)])
    context.addPath(stem.union(bridge).union(outer).subtracting(counter))
    context.setFillColor(butter.cgColor)
    context.fillPath()
}

/// Planner: a checkmark on Banana, reads like a to-do app.
try render("AppIconPlanner", background: banana) { context in
    context.setStrokeColor(nightInk.cgColor)
    context.setLineWidth(110)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.move(to: CGPoint(x: 250, y: 520))
    context.addLine(to: CGPoint(x: 430, y: 340))
    context.addLine(to: CGPoint(x: 780, y: 690))
    context.strokePath()
}

/// Plain: a Lilac dot on white, says nothing at all.
try render("AppIconPlain", background: .white) { context in
    context.setFillColor(lilac.cgColor)
    context.fillEllipse(in: CGRect(x: 312, y: 312, width: 400, height: 400))
}
