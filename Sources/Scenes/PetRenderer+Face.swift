import SwiftUI

extension PetRenderer {

    private static let ink = Color(hex: 0x1C120B)

    // MARK: Face

    static func drawFace(_ ctx: inout GraphicsContext, body: CGRect,
                         look: PetAppearance, pose: PetPose) {
        let w = body.width
        let eyeY = body.minY + body.height * 0.43
        let eyeDX = w * 0.19
        let eyeW = w * 0.13
        let eyeH = w * 0.17

        // Cheeks first, so the eyes sit on top.
        let blush: Double = [.love, .laughing, .happy].contains(pose.face) ? 0.6 : 0.38
        for side in [-1.0, 1.0] {
            let r = CGRect(x: body.midX + side * w * 0.3 - w * 0.08, y: eyeY + eyeH * 0.55,
                           width: w * 0.16, height: w * 0.09)
            ctx.fill(Path(ellipseIn: r), with: .color(look.cheeks.opacity(blush)))
        }

        for side in [-1.0, 1.0] {
            let center = CGPoint(x: body.midX + side * eyeDX + pose.look.x * eyeW * 0.2,
                                 y: eyeY + pose.look.y * eyeH * 0.12)
            drawEye(&ctx, center: center, width: eyeW, height: eyeH, side: side, pose: pose)
        }

        drawBrows(&ctx, body: body, eyeY: eyeY, eyeDX: eyeDX, eyeW: eyeW, eyeH: eyeH, face: pose.face)
        drawMouth(&ctx, center: CGPoint(x: body.midX + pose.look.x * w * 0.02, y: body.minY + body.height * 0.62),
                  width: w, pose: pose)
    }

    private static func drawEye(_ ctx: inout GraphicsContext, center c: CGPoint,
                                width ew: CGFloat, height eh: CGFloat, side: Double, pose: PetPose) {
        let line = StrokeStyle(lineWidth: ew * 0.26, lineCap: .round, lineJoin: .round)
        switch pose.face {
        case .laughing, .eating:
            // Happy squint: ^ ^
            var p = Path()
            p.move(to: CGPoint(x: c.x - ew * 0.5, y: c.y + eh * 0.12))
            p.addQuadCurve(to: CGPoint(x: c.x + ew * 0.5, y: c.y + eh * 0.12),
                           control: CGPoint(x: c.x, y: c.y - eh * 0.45))
            ctx.stroke(p, with: .color(ink), style: line)
        case .sleeping:
            var p = Path()
            p.move(to: CGPoint(x: c.x - ew * 0.5, y: c.y))
            p.addQuadCurve(to: CGPoint(x: c.x + ew * 0.5, y: c.y),
                           control: CGPoint(x: c.x, y: c.y + eh * 0.4))
            ctx.stroke(p, with: .color(ink), style: line)
        case .refusing:
            // Squeezed shut: > <
            var p = Path()
            let s = CGFloat(side)
            p.move(to: CGPoint(x: c.x - s * ew * 0.45, y: c.y - eh * 0.25))
            p.addLine(to: CGPoint(x: c.x + s * ew * 0.35, y: c.y))
            p.addLine(to: CGPoint(x: c.x - s * ew * 0.45, y: c.y + eh * 0.25))
            ctx.stroke(p, with: .color(ink), style: line)
        case .love:
            drawHeart(&ctx, center: c, size: ew * 1.3, color: Color(hex: 0xFF3D6E))
        default:
            let lid: CGFloat
            switch pose.face {
            case .sleepy, .sick: lid = 0.5
            case .surprised: lid = -0.1
            default: lid = 0
            }
            let open = max(0.08, (1 - pose.blink) * (1 - lid))
            let h = eh * open
            let rect = CGRect(x: c.x - ew / 2, y: c.y - h / 2 + (eh - h) * 0.25, width: ew, height: h)
            if open <= 0.12 {
                var p = Path()
                p.move(to: CGPoint(x: rect.minX, y: rect.midY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                ctx.stroke(p, with: .color(ink), style: line)
                return
            }
            ctx.fill(Path(ellipseIn: rect), with: .color(ink))
            // Catch-lights make the eyes feel alive.
            let spark = ew * 0.34
            let s1 = CGRect(x: rect.midX - spark * 0.1 + pose.look.x * ew * 0.08, y: rect.minY + h * 0.14,
                            width: spark, height: min(spark, h * 0.4))
            ctx.fill(Path(ellipseIn: s1), with: .color(.white))
            if pose.face == .happy {
                let s2 = CGRect(x: rect.minX + ew * 0.16, y: rect.maxY - h * 0.34, width: spark * 0.5, height: spark * 0.5)
                ctx.fill(Path(ellipseIn: s2), with: .color(.white.opacity(0.85)))
            }
            if pose.face == .sad {
                let tear = CGRect(x: c.x + CGFloat(side) * ew * 0.3, y: c.y + eh * 0.45 + CGFloat(sin(pose.time * 2)) * 2,
                                  width: ew * 0.3, height: ew * 0.42)
                ctx.fill(Path(ellipseIn: tear), with: .color(Color(hex: 0x6EC6FF).opacity(0.9)))
            }
        }
    }

    private static func drawBrows(_ ctx: inout GraphicsContext, body: CGRect, eyeY: CGFloat,
                                  eyeDX: CGFloat, eyeW: CGFloat, eyeH: CGFloat, face: PetPose.Face) {
        let slant: CGFloat
        switch face {
        // Positive lifts the inner end (worried), negative drops it (cross).
        case .angry: slant = -1
        case .sad, .sick: slant = 0.8
        default: return
        }
        for side in [-1.0, 1.0] {
            let s = CGFloat(side)
            let cx = body.midX + s * eyeDX
            let y = eyeY - eyeH * 0.78
            var p = Path()
            p.move(to: CGPoint(x: cx - s * eyeW * 0.6, y: y - slant * eyeH * 0.12))
            p.addLine(to: CGPoint(x: cx + s * eyeW * 0.5, y: y + slant * eyeH * 0.18))
            ctx.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: eyeW * 0.2, lineCap: .round))
        }
    }

    private static func drawMouth(_ ctx: inout GraphicsContext, center c: CGPoint, width w: CGFloat, pose: PetPose) {
        let mw = w * 0.16
        let line = StrokeStyle(lineWidth: w * 0.028, lineCap: .round, lineJoin: .round)
        var p = Path()
        switch pose.face {
        case .happy, .laughing:
            let open = pose.face == .laughing ? 1.5 : 1.0
            p.move(to: CGPoint(x: c.x - mw * 0.6 * open, y: c.y - mw * 0.1))
            p.addQuadCurve(to: CGPoint(x: c.x + mw * 0.6 * open, y: c.y - mw * 0.1),
                           control: CGPoint(x: c.x, y: c.y + mw * 1.1 * open))
            p.closeSubpath()
            ctx.fill(p, with: .color(ink))
            let tongue = CGRect(x: c.x - mw * 0.28, y: c.y + mw * 0.12 * open, width: mw * 0.56, height: mw * 0.32 * open)
            ctx.fill(Path(ellipseIn: tongue), with: .color(Color(hex: 0xFF6B7A)))
            return
        case .content, .love:
            p.move(to: CGPoint(x: c.x - mw * 0.45, y: c.y))
            p.addQuadCurve(to: CGPoint(x: c.x + mw * 0.45, y: c.y), control: CGPoint(x: c.x, y: c.y + mw * 0.55))
        case .sad:
            p.move(to: CGPoint(x: c.x - mw * 0.45, y: c.y + mw * 0.3))
            p.addQuadCurve(to: CGPoint(x: c.x + mw * 0.45, y: c.y + mw * 0.3), control: CGPoint(x: c.x, y: c.y - mw * 0.25))
        case .sick, .dirty, .refusing:
            p.move(to: CGPoint(x: c.x - mw * 0.5, y: c.y + mw * 0.1))
            p.addCurve(to: CGPoint(x: c.x + mw * 0.5, y: c.y + mw * 0.1),
                       control1: CGPoint(x: c.x - mw * 0.15, y: c.y - mw * 0.35),
                       control2: CGPoint(x: c.x + mw * 0.15, y: c.y + mw * 0.55))
        case .angry:
            p.move(to: CGPoint(x: c.x - mw * 0.5, y: c.y + mw * 0.2))
            for i in 1...4 {
                p.addLine(to: CGPoint(x: c.x - mw * 0.5 + mw * 0.25 * CGFloat(i), y: c.y + (i.isMultiple(of: 2) ? mw * 0.2 : 0)))
            }
        case .hungry, .surprised:
            let r = CGRect(x: c.x - mw * 0.28, y: c.y - mw * 0.05, width: mw * 0.56, height: mw * 0.62)
            ctx.fill(Path(ellipseIn: r), with: .color(ink))
            if pose.face == .hungry {
                let drool = CGRect(x: c.x + mw * 0.2, y: r.maxY - mw * 0.1, width: mw * 0.18,
                                   height: mw * (0.35 + 0.15 * CGFloat(sin(pose.time * 3))))
                ctx.fill(Path(roundedRect: drool, cornerRadius: mw * 0.09), with: .color(Color(hex: 0x9FDBFF)))
            }
            return
        case .eating:
            let open = 0.12 + pose.chew * 0.55
            let r = CGRect(x: c.x - mw * 0.4, y: c.y - mw * open * 0.3, width: mw * 0.8, height: mw * open)
            ctx.fill(Path(ellipseIn: r), with: .color(ink))
            return
        case .sleepy:
            let r = CGRect(x: c.x - mw * 0.14, y: c.y, width: mw * 0.28, height: mw * 0.3)
            ctx.fill(Path(ellipseIn: r), with: .color(ink))
            return
        case .sleeping:
            let breathe = 0.2 + 0.1 * CGFloat(sin(pose.time * 1.6))
            let r = CGRect(x: c.x - mw * 0.12, y: c.y, width: mw * 0.24, height: mw * breathe)
            ctx.fill(Path(ellipseIn: r), with: .color(ink))
            return
        }
        ctx.stroke(p, with: .color(ink), style: line)
    }

    // MARK: Senior

    static func drawSeniorDetails(_ ctx: inout GraphicsContext, body: CGRect) {
        let w = body.width
        let eyeY = body.minY + body.height * 0.43
        let frame = StrokeStyle(lineWidth: w * 0.02)
        for side in [-1.0, 1.0] {
            let c = CGPoint(x: body.midX + side * w * 0.19, y: eyeY)
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - w * 0.11, y: c.y - w * 0.11, width: w * 0.22, height: w * 0.22)),
                       with: .color(Color(hex: 0x5A4632)), style: frame)
            // Bushy white brows.
            let brow = CGRect(x: c.x - w * 0.09, y: c.y - w * 0.2, width: w * 0.18, height: w * 0.06)
            ctx.fill(Path(roundedRect: brow, cornerRadius: w * 0.03), with: .color(.white.opacity(0.9)))
        }
        var bridge = Path()
        bridge.move(to: CGPoint(x: body.midX - w * 0.08, y: eyeY))
        bridge.addLine(to: CGPoint(x: body.midX + w * 0.08, y: eyeY))
        ctx.stroke(bridge, with: .color(Color(hex: 0x5A4632)), style: frame)
    }

    // MARK: Hats

    static func drawHat(_ ctx: inout GraphicsContext, id: String, body: CGRect, look: PetAppearance) {
        let w = body.width
        let top = body.minY + body.height * 0.04
        let cx = body.midX
        switch id {
        case "hat.bow":
            for side in [-1.0, 1.0] {
                var p = Path()
                p.move(to: CGPoint(x: cx + w * 0.2, y: top))
                p.addLine(to: CGPoint(x: cx + w * 0.2 + side * w * 0.16, y: top - w * 0.09))
                p.addLine(to: CGPoint(x: cx + w * 0.2 + side * w * 0.16, y: top + w * 0.09))
                p.closeSubpath()
                ctx.fill(p, with: .color(Color(hex: 0xFF4F7B)))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: cx + w * 0.16, y: top - w * 0.04, width: w * 0.08, height: w * 0.08)),
                     with: .color(Color(hex: 0xD62E5C)))
        case "hat.cap":
            let dome = CGRect(x: cx - w * 0.3, y: top - w * 0.2, width: w * 0.6, height: w * 0.36)
            var p = Path()
            p.addArc(center: CGPoint(x: dome.midX, y: dome.maxY - w * 0.08), radius: w * 0.3,
                     startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            p.closeSubpath()
            ctx.fill(p, with: .color(Color(hex: 0x2F7BF6)))
            let brim = CGRect(x: cx, y: dome.maxY - w * 0.12, width: w * 0.46, height: w * 0.08)
            ctx.fill(Path(roundedRect: brim, cornerRadius: w * 0.04), with: .color(Color(hex: 0x1E56B8)))
        case "hat.flower":
            let c = CGPoint(x: cx - w * 0.22, y: top + w * 0.02)
            for i in 0..<6 {
                let a = Double(i) * .pi / 3
                let pc = CGPoint(x: c.x + CGFloat(cos(a)) * w * 0.07, y: c.y + CGFloat(sin(a)) * w * 0.07)
                ctx.fill(Path(ellipseIn: CGRect(x: pc.x - w * 0.055, y: pc.y - w * 0.055, width: w * 0.11, height: w * 0.11)),
                         with: .color(Color(hex: 0xFF8FB8)))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - w * 0.045, y: c.y - w * 0.045, width: w * 0.09, height: w * 0.09)),
                     with: .color(Color(hex: 0xFFD54A)))
        case "hat.party":
            var p = Path()
            p.move(to: CGPoint(x: cx - w * 0.16, y: top + w * 0.04))
            p.addLine(to: CGPoint(x: cx + w * 0.04, y: top - w * 0.4))
            p.addLine(to: CGPoint(x: cx + w * 0.2, y: top + w * 0.04))
            p.closeSubpath()
            ctx.fill(p, with: .linearGradient(Gradient(colors: [Color(hex: 0x7C4DFF), Color(hex: 0x00C2FF)]),
                                              startPoint: CGPoint(x: cx, y: top - w * 0.4),
                                              endPoint: CGPoint(x: cx, y: top)))
            drawStar(&ctx, center: CGPoint(x: cx + w * 0.04, y: top - w * 0.42), radius: w * 0.07, color: Color(hex: 0xFFD54A))
        case "hat.headphones":
            var band = Path()
            band.addArc(center: CGPoint(x: cx, y: body.minY + body.height * 0.4), radius: w * 0.48,
                        startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            ctx.stroke(band, with: .color(Color(hex: 0x2B2B33)), style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
            for side in [-1.0, 1.0] {
                let r = CGRect(x: cx + side * w * 0.47 - w * 0.09, y: body.minY + body.height * 0.3,
                               width: w * 0.18, height: w * 0.26)
                ctx.fill(Path(roundedRect: r, cornerRadius: w * 0.07), with: .color(Color(hex: 0xF99C00)))
            }
        case "hat.crown":
            var p = Path()
            let base = top + w * 0.02
            p.move(to: CGPoint(x: cx - w * 0.22, y: base))
            p.addLine(to: CGPoint(x: cx - w * 0.24, y: base - w * 0.22))
            p.addLine(to: CGPoint(x: cx - w * 0.11, y: base - w * 0.1))
            p.addLine(to: CGPoint(x: cx, y: base - w * 0.28))
            p.addLine(to: CGPoint(x: cx + w * 0.11, y: base - w * 0.1))
            p.addLine(to: CGPoint(x: cx + w * 0.24, y: base - w * 0.22))
            p.addLine(to: CGPoint(x: cx + w * 0.22, y: base))
            p.closeSubpath()
            ctx.fill(p, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0xE0A100)]),
                                              startPoint: CGPoint(x: cx, y: base - w * 0.28),
                                              endPoint: CGPoint(x: cx, y: base)))
            ctx.fill(Path(ellipseIn: CGRect(x: cx - w * 0.035, y: base - w * 0.1, width: w * 0.07, height: w * 0.07)),
                     with: .color(Color(hex: 0xFF3D6E)))
        default:
            break
        }
    }

    // MARK: Extras

    static func drawExtras(_ ctx: inout GraphicsContext, body: CGRect, pose: PetPose, size: CGSize) {
        let w = body.width
        switch pose.face {
        case .sleeping:
            for i in 0..<3 {
                let phase = (pose.time * 0.5 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let x = body.maxX - w * 0.05 + CGFloat(phase) * w * 0.3 + CGFloat(sin(phase * 6)) * 4
                let y = body.minY - CGFloat(phase) * w * 0.5
                let text = Text("z").font(.system(size: w * (0.12 + 0.1 * CGFloat(phase)), weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: 0x9DB7FF).opacity(1 - phase))
                ctx.draw(text, at: CGPoint(x: x, y: y))
            }
        case .dirty:
            for i in 0..<2 {
                let a = pose.time * (2.4 + Double(i)) + Double(i) * 2
                let c = CGPoint(x: body.midX + CGFloat(cos(a)) * w * 0.62, y: body.minY + body.height * 0.3 + CGFloat(sin(a * 1.3)) * w * 0.22)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)), with: .color(ink))
                let flap = CGFloat(abs(sin(pose.time * 40))) * 4 + 2
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - 4, y: c.y - flap - 2, width: 5, height: flap)), with: .color(.white.opacity(0.7)))
            }
        case .sick:
            let drop = CGRect(x: body.maxX - w * 0.16, y: body.minY + body.height * 0.18 + CGFloat(sin(pose.time * 2)) * 3,
                              width: w * 0.08, height: w * 0.12)
            ctx.fill(Path(ellipseIn: drop), with: .color(Color(hex: 0x8FD3FF)))
        case .angry:
            let c = CGPoint(x: body.maxX - w * 0.08, y: body.minY + body.height * 0.08)
            let pulse = 1 + 0.15 * CGFloat(sin(pose.time * 10))
            for i in 0..<4 {
                var mark = ctx
                mark.translateBy(x: c.x, y: c.y)
                mark.rotate(by: .degrees(Double(i) * 90 + 45))
                let r = CGRect(x: -w * 0.02, y: w * 0.02 * pulse, width: w * 0.04, height: w * 0.08 * pulse)
                mark.fill(Path(roundedRect: r, cornerRadius: w * 0.02), with: .color(Color(hex: 0xFF3B30)))
            }
        default:
            break
        }
    }

    static func drawHeart(_ ctx: inout GraphicsContext, center c: CGPoint, size s: CGFloat, color: Color) {
        ctx.fill(heartPath(center: c, size: s), with: .color(color))
    }

    static func heartPath(center c: CGPoint, size s: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y + s * 0.35))
        p.addCurve(to: CGPoint(x: c.x - s * 0.5, y: c.y - s * 0.1),
                   control1: CGPoint(x: c.x - s * 0.1, y: c.y + s * 0.2),
                   control2: CGPoint(x: c.x - s * 0.5, y: c.y + s * 0.15))
        p.addArc(center: CGPoint(x: c.x - s * 0.25, y: c.y - s * 0.12), radius: s * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: c.x + s * 0.25, y: c.y - s * 0.12), radius: s * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: c.x, y: c.y + s * 0.35),
                   control1: CGPoint(x: c.x + s * 0.5, y: c.y + s * 0.15),
                   control2: CGPoint(x: c.x + s * 0.1, y: c.y + s * 0.2))
        p.closeSubpath()
        return p
    }

    // MARK: Egg

    /// The egg on the splash, in onboarding and in the widget.
    static func drawEgg(_ ctx: inout GraphicsContext, in size: CGSize, wobble: Angle,
                        cracks: Int, glow: CGFloat = 0) {
        let h = size.height * 0.72
        let w = h * 0.78
        let bottom = size.height * 0.9
        let rect = CGRect(x: size.width / 2 - w / 2, y: bottom - h, width: w, height: h)
        ctx.fill(Path(ellipseIn: CGRect(x: rect.midX - w * 0.42, y: bottom - w * 0.07, width: w * 0.84, height: w * 0.14)),
                 with: .color(.black.opacity(0.22)))
        var egg = ctx
        egg.translateBy(x: rect.midX, y: bottom)
        egg.rotate(by: wobble)
        egg.translateBy(x: -rect.midX, y: -bottom)
        if glow > 0 {
            let halo = rect.insetBy(dx: -w * 0.35, dy: -h * 0.25)
            egg.fill(Path(ellipseIn: halo), with: .radialGradient(
                Gradient(colors: [Color(hex: 0xF99C00).opacity(Double(glow) * 0.55), Color(hex: 0xF99C00).opacity(0)]),
                center: CGPoint(x: rect.midX, y: rect.midY), startRadius: w * 0.2, endRadius: halo.width / 2))
        }
        let path = bodyPath(rect, taper: 0.9)
        egg.fill(path, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFE08A), Color(hex: 0xF99C00), Color(hex: 0xC85A00)]),
                                             startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                             endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
        // Spots.
        for (dx, dy, r) in [(0.28, 0.3, 0.1), (0.66, 0.52, 0.13), (0.36, 0.72, 0.08)] {
            let c = CGPoint(x: rect.minX + w * dx, y: rect.minY + h * dy)
            egg.fill(Path(ellipseIn: CGRect(x: c.x - w * r, y: c.y - w * r * 0.8, width: w * r * 2, height: w * r * 1.6)),
                     with: .color(.white.opacity(0.28)))
        }
        egg.fill(Path(ellipseIn: CGRect(x: rect.minX + w * 0.2, y: rect.minY + h * 0.1, width: w * 0.22, height: h * 0.14)),
                 with: .color(.white.opacity(0.45)))
        guard cracks > 0 else { return }
        var crack = Path()
        let y = rect.minY + h * 0.42
        let steps = 2 + cracks * 2
        crack.move(to: CGPoint(x: rect.minX + w * 0.08, y: y))
        for i in 1...steps {
            let x = rect.minX + w * 0.08 + w * 0.84 * CGFloat(i) / CGFloat(steps)
            crack.addLine(to: CGPoint(x: x, y: y + (i.isMultiple(of: 2) ? 0 : -h * 0.06)))
        }
        egg.stroke(crack, with: .color(Color(hex: 0x3A1E08)),
                   style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round, lineJoin: .round))
    }
}
