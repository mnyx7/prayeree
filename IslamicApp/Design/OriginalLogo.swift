import AppKit
let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(red: 0.97, green: 0.96, blue: 0.91, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
// Original asymmetric crescent, drawn with cubic curves rather than a system glyph.
let moon = CGMutablePath()
moon.move(to: CGPoint(x: 660, y: 835))
moon.addCurve(to: CGPoint(x: 245, y: 470), control1: CGPoint(x: 424, y: 880), control2: CGPoint(x: 205, y: 721))
moon.addCurve(to: CGPoint(x: 741, y: 242), control1: CGPoint(x: 278, y: 201), control2: CGPoint(x: 566, y: 103))
moon.addCurve(to: CGPoint(x: 802, y: 365), control1: CGPoint(x: 781, y: 277), control2: CGPoint(x: 801, y: 324))
moon.addCurve(to: CGPoint(x: 413, y: 499), control1: CGPoint(x: 631, y: 266), control2: CGPoint(x: 425, y: 334))
moon.addCurve(to: CGPoint(x: 660, y: 835), control1: CGPoint(x: 390, y: 671), control2: CGPoint(x: 509, y: 782))
moon.closeSubpath()
let moonColor = CGColor(red: 0.08, green: 0.39, blue: 0.29, alpha: 1); context.setFillColor(moonColor); context.addPath(moon); context.fillPath()
let star = CGMutablePath()
for i in 0..<10 {
    let angle = Double.pi / 2 + Double(i) * Double.pi / 5 + 0.13
    let radius = i.isMultiple(of: 2) ? 107.0 : 46.0
    let point = CGPoint(x: 690 + cos(angle) * radius, y: 624 + sin(angle) * radius)
    if i == 0 { star.move(to: point) } else { star.addLine(to: point) }
}
star.closeSubpath()
context.setFillColor(CGColor(red: 0.88, green: 0.67, blue: 0.22, alpha: 1))
context.addPath(star); context.fillPath()
let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
