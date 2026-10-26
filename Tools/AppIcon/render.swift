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

/// Charm: a Butter "n" on Cobalt, the wordmark's first letter.
try render("AppIcon", background: cobalt) { context in
    let font = NSFont(name: "BricolageGrotesqueCondensed-ExtraBold", size: 720)!
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: "n", attributes: [.font: font, .foregroundColor: butter])
    )
    let ink = CTLineGetImageBounds(line, context)
    context.textPosition = CGPoint(x: (size - ink.width) / 2 - ink.minX, y: (size - ink.height) / 2 - ink.minY)
    CTLineDraw(line, context)
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
