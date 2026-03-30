#!/usr/bin/env swift
//
// generate-app-icon.swift
// Draws the LanternMark programmatically at 1024x1024 on a forest-canopy gradient.
//
// Usage: swift scripts/generate-app-icon.swift
// Output: scripts/LanternAppIcon-1024.png

import AppKit
import CoreGraphics

let size: CGFloat = 1024
let outputPath = "scripts/LanternAppIcon-1024.png"

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: Int(size) * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("ERROR: Cannot create CGContext")
    exit(1)
}

// Flip to top-down coordinates
ctx.translateBy(x: 0, y: size)
ctx.scaleBy(x: 1, y: -1)

// Colors
let gold = NSColor(red: 0xC4/255.0, green: 0x90/255.0, blue: 0x20/255.0, alpha: 1).cgColor
let darkBg = NSColor(red: 0x0E/255.0, green: 0x22/255.0, blue: 0x1C/255.0, alpha: 1).cgColor
let cream = NSColor(red: 0xF5/255.0, green: 0xEC/255.0, blue: 0xD5/255.0, alpha: 1).cgColor

// -- Background: radial gradient --
let bgColors: [CGColor] = [
    NSColor(red: 0x1E/255.0, green: 0x45/255.0, blue: 0x38/255.0, alpha: 1).cgColor,
    NSColor(red: 0x17/255.0, green: 0x33/255.0, blue: 0x29/255.0, alpha: 1).cgColor,
    NSColor(red: 0x0E/255.0, green: 0x22/255.0, blue: 0x1C/255.0, alpha: 1).cgColor,
]
if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: [0.0, 0.5, 1.0]) {
    ctx.drawRadialGradient(gradient, startCenter: CGPoint(x: 512, y: 512), startRadius: 0, endCenter: CGPoint(x: 512, y: 512), endRadius: size * 0.6, options: [.drawsAfterEndLocation])
}

// -- Subtle warm glow --
let glowColors: [CGColor] = [
    NSColor(red: 0xC4/255.0, green: 0x90/255.0, blue: 0x20/255.0, alpha: 0.12).cgColor,
    NSColor(red: 0xC4/255.0, green: 0x90/255.0, blue: 0x20/255.0, alpha: 0.0).cgColor,
]
if let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors as CFArray, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 500), startRadius: 0, endCenter: CGPoint(x: 512, y: 500), endRadius: 320, options: [.drawsAfterEndLocation])
}

// -- Lantern mark (scaled up to fill more of the icon) --
// Lantern spans y≈156 to y≈756, center at y≈456. x is centered at 512.
// Scale around the lantern's actual center so it stays centered in the icon.
let lanternScale: CGFloat = 1.35
let lanternCenterX: CGFloat = 512
let lanternCenterY: CGFloat = 456
ctx.saveGState()
ctx.translateBy(x: size / 2, y: size / 2)
ctx.scaleBy(x: lanternScale, y: lanternScale)
ctx.translateBy(x: -lanternCenterX, y: -lanternCenterY)
// Drawn centered at (512, ~500), matching the original LanternMark proportions:
// - Rounded arch handle
// - Flat top cap wider than body
// - Tapered body: wider at shoulders, narrowing toward bottom
// - Oval window with cream fill
// - Flat bottom cap narrower than top

let cx: CGFloat = 512

// HANDLE: thick semicircular arch
let handleW: CGFloat = 36
let handleRadius: CGFloat = 54
let handleCY: CGFloat = 228
ctx.setStrokeColor(gold)
ctx.setLineWidth(handleW)
ctx.setLineCap(.round)
ctx.beginPath()
ctx.addArc(center: CGPoint(x: cx, y: handleCY), radius: handleRadius, startAngle: .pi, endAngle: 0, clockwise: false)
ctx.strokePath()

// TOP CAP
let capY: CGFloat = 264
let capW: CGFloat = 220
let capH: CGFloat = 40
let capR: CGFloat = 10
ctx.setFillColor(gold)
let capPath = CGPath(roundedRect: CGRect(x: cx - capW/2, y: capY, width: capW, height: capH), cornerWidth: capR, cornerHeight: capR, transform: nil)
ctx.addPath(capPath)
ctx.fillPath()

// BODY: tapered shape — wider at top, narrower at bottom
// Using a custom path for the outer body
let bodyTop: CGFloat = capY + capH
let bodyBottom: CGFloat = 720
let topHalfW: CGFloat = 110  // half-width at top
let midHalfW: CGFloat = 118  // half-width at widest (belly)
let botHalfW: CGFloat = 88   // half-width at bottom
let topR: CGFloat = 20       // corner radius at top
let botR: CGFloat = 36       // corner radius at bottom (more rounded)
let bellyY: CGFloat = (bodyTop + bodyBottom) / 2 - 20  // widest point slightly above center

// Outer body path
let outerBody = CGMutablePath()
outerBody.move(to: CGPoint(x: cx - topHalfW + topR, y: bodyTop))
outerBody.addLine(to: CGPoint(x: cx + topHalfW - topR, y: bodyTop))
outerBody.addQuadCurve(to: CGPoint(x: cx + topHalfW, y: bodyTop + topR), control: CGPoint(x: cx + topHalfW, y: bodyTop))
// Right side: top to belly
outerBody.addCurve(to: CGPoint(x: cx + midHalfW, y: bellyY),
                   control1: CGPoint(x: cx + topHalfW, y: bodyTop + 60),
                   control2: CGPoint(x: cx + midHalfW, y: bellyY - 80))
// Right side: belly to bottom
outerBody.addCurve(to: CGPoint(x: cx + botHalfW, y: bodyBottom - botR),
                   control1: CGPoint(x: cx + midHalfW, y: bellyY + 80),
                   control2: CGPoint(x: cx + botHalfW, y: bodyBottom - 100))
outerBody.addQuadCurve(to: CGPoint(x: cx + botHalfW - botR, y: bodyBottom), control: CGPoint(x: cx + botHalfW, y: bodyBottom))
outerBody.addLine(to: CGPoint(x: cx - botHalfW + botR, y: bodyBottom))
outerBody.addQuadCurve(to: CGPoint(x: cx - botHalfW, y: bodyBottom - botR), control: CGPoint(x: cx - botHalfW, y: bodyBottom))
// Left side: bottom to belly
outerBody.addCurve(to: CGPoint(x: cx - midHalfW, y: bellyY),
                   control1: CGPoint(x: cx - botHalfW, y: bodyBottom - 100),
                   control2: CGPoint(x: cx - midHalfW, y: bellyY + 80))
// Left side: belly to top
outerBody.addCurve(to: CGPoint(x: cx - topHalfW, y: bodyTop + topR),
                   control1: CGPoint(x: cx - midHalfW, y: bellyY - 80),
                   control2: CGPoint(x: cx - topHalfW, y: bodyTop + 60))
outerBody.addQuadCurve(to: CGPoint(x: cx - topHalfW + topR, y: bodyTop), control: CGPoint(x: cx - topHalfW, y: bodyTop))
outerBody.closeSubpath()

ctx.setFillColor(gold)
ctx.addPath(outerBody)
ctx.fillPath()

// Inner cutout — same shape inset by stroke width
let sw: CGFloat = 36
let iTopHalfW = topHalfW - sw
let iMidHalfW = midHalfW - sw
let iBotHalfW = botHalfW - sw
let iBodyTop = bodyTop + sw
let iBodyBottom = bodyBottom - sw
let iBellyY = bellyY
let iTopR = max(topR - sw/2, 4)
let iBotR = max(botR - sw/2, 8)

let innerBody = CGMutablePath()
innerBody.move(to: CGPoint(x: cx - iTopHalfW + iTopR, y: iBodyTop))
innerBody.addLine(to: CGPoint(x: cx + iTopHalfW - iTopR, y: iBodyTop))
innerBody.addQuadCurve(to: CGPoint(x: cx + iTopHalfW, y: iBodyTop + iTopR), control: CGPoint(x: cx + iTopHalfW, y: iBodyTop))
innerBody.addCurve(to: CGPoint(x: cx + iMidHalfW, y: iBellyY),
                   control1: CGPoint(x: cx + iTopHalfW, y: iBodyTop + 50),
                   control2: CGPoint(x: cx + iMidHalfW, y: iBellyY - 70))
innerBody.addCurve(to: CGPoint(x: cx + iBotHalfW, y: iBodyBottom - iBotR),
                   control1: CGPoint(x: cx + iMidHalfW, y: iBellyY + 70),
                   control2: CGPoint(x: cx + iBotHalfW, y: iBodyBottom - 80))
innerBody.addQuadCurve(to: CGPoint(x: cx + iBotHalfW - iBotR, y: iBodyBottom), control: CGPoint(x: cx + iBotHalfW, y: iBodyBottom))
innerBody.addLine(to: CGPoint(x: cx - iBotHalfW + iBotR, y: iBodyBottom))
innerBody.addQuadCurve(to: CGPoint(x: cx - iBotHalfW, y: iBodyBottom - iBotR), control: CGPoint(x: cx - iBotHalfW, y: iBodyBottom))
innerBody.addCurve(to: CGPoint(x: cx - iMidHalfW, y: iBellyY),
                   control1: CGPoint(x: cx - iBotHalfW, y: iBodyBottom - 80),
                   control2: CGPoint(x: cx - iMidHalfW, y: iBellyY + 70))
innerBody.addCurve(to: CGPoint(x: cx - iTopHalfW, y: iBodyTop + iTopR),
                   control1: CGPoint(x: cx - iMidHalfW, y: iBellyY - 70),
                   control2: CGPoint(x: cx - iTopHalfW, y: iBodyTop + 50))
innerBody.addQuadCurve(to: CGPoint(x: cx - iTopHalfW + iTopR, y: iBodyTop), control: CGPoint(x: cx - iTopHalfW, y: iBodyTop))
innerBody.closeSubpath()

ctx.setFillColor(darkBg)
ctx.addPath(innerBody)
ctx.fillPath()

// WINDOW: cream oval in center of body
let windowCY: CGFloat = (bodyTop + bodyBottom) / 2 - 10
let windowRX: CGFloat = 48
let windowRY: CGFloat = 58
ctx.setFillColor(cream)
ctx.fillEllipse(in: CGRect(x: cx - windowRX, y: windowCY - windowRY, width: windowRX * 2, height: windowRY * 2))

// BOTTOM CAP
let botCapY: CGFloat = bodyBottom
let botCapW: CGFloat = 180
let botCapH: CGFloat = 36
let botCapR: CGFloat = 10
ctx.setFillColor(gold)
let botCapPath = CGPath(roundedRect: CGRect(x: cx - botCapW/2, y: botCapY, width: botCapW, height: botCapH), cornerWidth: botCapR, cornerHeight: botCapR, transform: nil)
ctx.addPath(botCapPath)
ctx.fillPath()

ctx.restoreGState()

// -- Write PNG --
guard let outputImage = ctx.makeImage() else {
    print("ERROR: Cannot create output image")
    exit(1)
}

let url = URL(fileURLWithPath: outputPath)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    print("ERROR: Cannot create image destination")
    exit(1)
}
CGImageDestinationAddImage(destination, outputImage, nil)
guard CGImageDestinationFinalize(destination) else {
    print("ERROR: Cannot finalize PNG")
    exit(1)
}

print("App icon written to \(outputPath) (\(Int(size))x\(Int(size)))")
