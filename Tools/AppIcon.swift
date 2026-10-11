// Draws the NomTracker app icon: a bitten apple on an orange background.
// Usage: swift Tools/AppIcon.swift NomTracker/Assets.xcassets/AppIcon.appiconset/AppIcon.png
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}

/// A context with top-left origin, like the coordinates below.
func makeContext(alpha: Bool) -> CGContext {
    let info = alpha ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: info.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func fillGradient(_ ctx: CGContext, _ colors: [CGColor], from: CGPoint, to: CGPoint) {
    let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(gradient, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

// MARK: Shapes

let apple: CGPath = {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: 512, y: 360))
    p.addCurve(to: CGPoint(x: 740, y: 350), control1: CGPoint(x: 560, y: 310), control2: CGPoint(x: 680, y: 290))
    p.addCurve(to: CGPoint(x: 760, y: 730), control1: CGPoint(x: 820, y: 430), control2: CGPoint(x: 820, y: 620))
    p.addCurve(to: CGPoint(x: 580, y: 850), control1: CGPoint(x: 710, y: 830), control2: CGPoint(x: 630, y: 880))
    p.addCurve(to: CGPoint(x: 444, y: 850), control1: CGPoint(x: 550, y: 835), control2: CGPoint(x: 474, y: 835))
    p.addCurve(to: CGPoint(x: 264, y: 730), control1: CGPoint(x: 394, y: 880), control2: CGPoint(x: 314, y: 830))
    p.addCurve(to: CGPoint(x: 284, y: 350), control1: CGPoint(x: 204, y: 620), control2: CGPoint(x: 204, y: 430))
    p.addCurve(to: CGPoint(x: 512, y: 360), control1: CGPoint(x: 344, y: 290), control2: CGPoint(x: 464, y: 310))
    p.closeSubpath()
    return p
}()

/// Overlapping circles on the right side make a scalloped bite.
let biteCircles: [(CGPoint, CGFloat)] = [
    (CGPoint(x: 820, y: 450), 95),
    (CGPoint(x: 842, y: 565), 100),
    (CGPoint(x: 820, y: 680), 95),
]

func circles(grownBy grow: CGFloat) -> CGPath {
    let p = CGMutablePath()
    for (c, r) in biteCircles {
        let r = r + grow
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    }
    return p
}

let leaf: CGPath = {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: 535, y: 300))
    p.addCurve(to: CGPoint(x: 730, y: 215), control1: CGPoint(x: 575, y: 205), control2: CGPoint(x: 680, y: 180))
    p.addCurve(to: CGPoint(x: 535, y: 300), control1: CGPoint(x: 700, y: 290), control2: CGPoint(x: 605, y: 325))
    p.closeSubpath()
    return p
}()

// MARK: Apple layer (transparent, so the bite can be cut out)

let layer = makeContext(alpha: true)

// Stem, drawn first so the apple covers its base.
layer.setStrokeColor(color(0.40, 0.24, 0.12))
layer.setLineWidth(34)
layer.setLineCap(.round)
layer.move(to: CGPoint(x: 508, y: 390))
layer.addQuadCurve(to: CGPoint(x: 540, y: 225), control: CGPoint(x: 505, y: 290))
layer.strokePath()

// Body: red, lighter toward the upper left.
layer.saveGState()
layer.addPath(apple)
layer.clip()
let bodyGradient = CGGradient(colorsSpace: space, colors: [color(0.97, 0.30, 0.25), color(0.86, 0.13, 0.14), color(0.62, 0.06, 0.09)] as CFArray, locations: [0, 0.55, 1])!
layer.drawRadialGradient(bodyGradient, startCenter: CGPoint(x: 400, y: 470), startRadius: 0,
                         endCenter: CGPoint(x: 512, y: 580), endRadius: 380, options: [.drawsAfterEndLocation])
// Cream flesh just inside the bite edge.
layer.addPath(circles(grownBy: 26))
layer.setFillColor(color(0.99, 0.94, 0.80))
layer.fillPath()
layer.restoreGState()

// Shine.
layer.saveGState()
layer.translateBy(x: 365, y: 480)
layer.rotate(by: 0.35)
layer.setFillColor(color(1, 1, 1, 0.30))
layer.fillEllipse(in: CGRect(x: -40, y: -85, width: 80, height: 170))
layer.restoreGState()

// Cut out the bite.
layer.setBlendMode(.clear)
layer.addPath(circles(grownBy: 0))
layer.fillPath()
layer.setBlendMode(.normal)

// Leaf with a center vein.
layer.saveGState()
layer.addPath(leaf)
layer.clip()
fillGradient(layer, [color(0.42, 0.76, 0.30), color(0.18, 0.50, 0.17)], from: CGPoint(x: 600, y: 200), to: CGPoint(x: 660, y: 300))
layer.restoreGState()
layer.setStrokeColor(color(0.70, 0.90, 0.55, 0.8))
layer.setLineWidth(6)
layer.move(to: CGPoint(x: 548, y: 292))
layer.addQuadCurve(to: CGPoint(x: 712, y: 220), control: CGPoint(x: 630, y: 240))
layer.strokePath()

let appleImage = layer.makeImage()!

// MARK: Final icon (opaque)

let icon = makeContext(alpha: false)
fillGradient(icon, [color(0.98, 0.62, 0.30), color(0.90, 0.42, 0.18)], from: CGPoint(x: 512, y: 0), to: CGPoint(x: 512, y: 1024))

// Soft shadow under the apple.
icon.saveGState()
icon.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: color(0.35, 0.12, 0.02, 0.45))
// Undo the flip for drawing the image, which CoreGraphics draws bottom-up.
icon.translateBy(x: 0, y: CGFloat(size))
icon.scaleBy(x: 1, y: -1)
icon.draw(appleImage, in: CGRect(x: 0, y: 0, width: size, height: size))
icon.restoreGState()

let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png")
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, icon.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not write \(output.path)") }
print("Wrote \(output.path)")
