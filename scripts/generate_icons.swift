import AppKit
import Foundation

func savePNG(_ image: NSImage, to path: String, pixels: Int? = nil) {
    let size = pixels ?? Int(image.size.width)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return }
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    try? data.write(to: URL(fileURLWithPath: path))
}

func appIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
    let inset = size * 0.12
    NSColor(red: 0.76, green: 0.37, blue: 0.24, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2), xRadius: size * 0.18, yRadius: size * 0.18).fill()
    let bubble = NSBezierPath(roundedRect: NSRect(x: size * 0.28, y: size * 0.34, width: size * 0.44, height: size * 0.32), xRadius: size * 0.06, yRadius: size * 0.06)
    NSColor(red: 0.1, green: 0.1, blue: 0.13, alpha: 1).setFill()
    bubble.fill()
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size * 0.22, weight: .bold),
        .foregroundColor: NSColor(red: 0.91, green: 0.45, blue: 0.23, alpha: 1)
    ]
    let text = "ع" as NSString
    let ts = text.size(withAttributes: attrs)
    text.draw(at: NSPoint(x: (size - ts.width) / 2, y: size * 0.38), withAttributes: attrs)
    image.unlockFocus()
    return image
}

func menuBarIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    NSColor.black.setStroke()
    let path = NSBezierPath(roundedRect: NSRect(x: 2, y: 3, width: size - 4, height: size - 7), xRadius: 3, yRadius: 3)
    path.lineWidth = 1.5
    path.stroke()
    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: size * 0.35, y: 3))
    tail.line(to: NSPoint(x: size * 0.28, y: 0))
    tail.line(to: NSPoint(x: size * 0.42, y: 3))
    tail.lineWidth = 1.5
    tail.stroke()
    image.unlockFocus()
    return image
}

@discardableResult
func runShell(_ command: String) -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-lc", command]
    try? process.run()
    process.waitUntilExit()
    return process.terminationStatus
}

let root = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
let assets = (root as NSString).appendingPathComponent("ClaudeRTL/Assets.xcassets")
let appIconDir = (assets as NSString).appendingPathComponent("AppIcon.appiconset")
let menuDir = (assets as NSString).appendingPathComponent("MenuBarIcon.imageset")

try? FileManager.default.createDirectory(atPath: appIconDir, withIntermediateDirectories: true)
try? FileManager.default.createDirectory(atPath: menuDir, withIntermediateDirectories: true)

let resourcesDir = (root as NSString).appendingPathComponent("ClaudeRTL/Resources")
let source1024 = (resourcesDir as NSString).appendingPathComponent("claude-ai-icon.png")
if !FileManager.default.fileExists(atPath: source1024) {
    try? FileManager.default.createDirectory(atPath: resourcesDir, withIntermediateDirectories: true)
    savePNG(appIcon(size: 1024), to: source1024, pixels: 1024)
}

let sipsScript = """
cd '\(appIconDir)' && \
sips -z 16 16     '\(source1024)' --out icon_16x16.png && \
sips -z 32 32     '\(source1024)' --out icon_16x16@2x.png && \
sips -z 32 32     '\(source1024)' --out icon_32x32.png && \
sips -z 64 64     '\(source1024)' --out icon_32x32@2x.png && \
sips -z 128 128   '\(source1024)' --out icon_128x128.png && \
sips -z 256 256   '\(source1024)' --out icon_128x128@2x.png && \
sips -z 256 256   '\(source1024)' --out icon_256x256.png && \
sips -z 512 512   '\(source1024)' --out icon_256x256@2x.png && \
sips -z 512 512   '\(source1024)' --out icon_512x512.png && \
sips -z 1024 1024 '\(source1024)' --out icon_512x512@2x.png
"""
runShell(sipsScript)

savePNG(menuBarIcon(size: 18), to: (menuDir as NSString).appendingPathComponent("MenuBarIcon.png"))
savePNG(menuBarIcon(size: 36), to: (menuDir as NSString).appendingPathComponent("MenuBarIcon@2x.png"))

print("Icons written to \(assets)")
