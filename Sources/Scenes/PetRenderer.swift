import SwiftUI

// MARK: - Appearance

/// Colours and features of one body. Babies, children and teens share the
/// warm ividi.dev tones; each adult form has its own look.
struct PetAppearance: Equatable {

    enum Ears: Equatable { case none, nubs, cat, bunny, antenna, horns, leaf, flame, puffs }
    enum Mark: Equatable { case none, star, crescent, speckles, rays }

    var top: Color
    var bottom: Color
    var belly: Color
    var cheeks: Color
    var ears: Ears
    var mark: Mark
    /// Width relative to height.
    var aspect: CGFloat
    /// How much narrower the head is than the base (0 = round, 1 = pear).
    var taper: CGFloat
    /// Share of the canvas the body fills vertically.
    var scale: CGFloat
    var isSenior = false

    static func of(stage: LifeStage, form: AdultForm?) -> PetAppearance {
        var look: PetAppearance
        switch stage {
        case .egg, .baby:
            look = PetAppearance(top: Color(hex: 0xFFD66B), bottom: Color(hex: 0xF9A400),
                                 belly: Color(hex: 0xFFF1C9), cheeks: Color(hex: 0xFF7A59),
                                 ears: .none, mark: .none, aspect: 1.08, taper: 0.1, scale: 0.46)
        case .child:
            look = PetAppearance(top: Color(hex: 0xFFC65A), bottom: Color(hex: 0xF08A00),
                                 belly: Color(hex: 0xFFEBC0), cheeks: Color(hex: 0xFF6E4E),
                                 ears: .nubs, mark: .none, aspect: 0.98, taper: 0.2, scale: 0.56)
        case .teen:
            look = PetAppearance(top: Color(hex: 0xFFB24D), bottom: Color(hex: 0xDD7400),
                                 belly: Color(hex: 0xFFE2B3), cheeks: Color(hex: 0xFF5E45),
                                 ears: .cat, mark: .none, aspect: 0.86, taper: 0.28, scale: 0.64)
        case .adult, .senior:
            look = Self.adult(form ?? .pebble)
        }
        if stage == .senior {
            look.isSenior = true
            look.top = look.top.blended(with: .gray, amount: 0.25)
            look.bottom = look.bottom.blended(with: .gray, amount: 0.25)
        }
        return look
    }

    private static func adult(_ form: AdultForm) -> PetAppearance {
        switch form {
        case .astro:
            return PetAppearance(top: Color(hex: 0x9C8CFF), bottom: Color(hex: 0x4A38D0),
                                 belly: Color(hex: 0xD9D3FF), cheeks: Color(hex: 0xFF8AD8),
                                 ears: .antenna, mark: .star, aspect: 0.9, taper: 0.25, scale: 0.72)
        case .luna:
            return PetAppearance(top: Color(hex: 0xD6E4FF), bottom: Color(hex: 0x7089D6),
                                 belly: Color(hex: 0xF2F6FF), cheeks: Color(hex: 0xB9A8FF),
                                 ears: .bunny, mark: .crescent, aspect: 0.86, taper: 0.3, scale: 0.7)
        case .pudding:
            return PetAppearance(top: Color(hex: 0xFFE0A8), bottom: Color(hex: 0xD98B35),
                                 belly: Color(hex: 0xFFF3DC), cheeks: Color(hex: 0xFF7E6B),
                                 ears: .nubs, mark: .none, aspect: 1.32, taper: 0.05, scale: 0.62)
        case .sunny:
            return PetAppearance(top: Color(hex: 0xFFEA6B), bottom: Color(hex: 0xFFAA00),
                                 belly: Color(hex: 0xFFF7C8), cheeks: Color(hex: 0xFF6F3C),
                                 ears: .none, mark: .rays, aspect: 0.95, taper: 0.15, scale: 0.68)
        case .nimbus:
            return PetAppearance(top: Color(hex: 0xDDF4FF), bottom: Color(hex: 0x74BDEB),
                                 belly: Color(hex: 0xFFFFFF), cheeks: Color(hex: 0xFF9BB3),
                                 ears: .puffs, mark: .none, aspect: 1.05, taper: 0.1, scale: 0.68)
        case .ember:
            return PetAppearance(top: Color(hex: 0xFF9A55), bottom: Color(hex: 0xD6361C),
                                 belly: Color(hex: 0xFFD3A8), cheeks: Color(hex: 0xFFE14D),
                                 ears: .flame, mark: .none, aspect: 0.88, taper: 0.32, scale: 0.7)
        case .pebble:
            return PetAppearance(top: Color(hex: 0xD3CCC2), bottom: Color(hex: 0x8C8479),
                                 belly: Color(hex: 0xECE7E0), cheeks: Color(hex: 0xE39A8B),
                                 ears: .leaf, mark: .speckles, aspect: 1.0, taper: 0.12, scale: 0.64)
        case .grumble:
            return PetAppearance(top: Color(hex: 0x8A6A8F), bottom: Color(hex: 0x3F2A47),
                                 belly: Color(hex: 0xB9A0BD), cheeks: Color(hex: 0xE0607E),
                                 ears: .horns, mark: .none, aspect: 0.96, taper: 0.2, scale: 0.68)
        }
    }
}

// MARK: - Pose

/// Everything that moves. The view recomputes this every frame; the widget
/// uses a still one.
struct PetPose {
    enum Face: Equatable {
        case happy, content, sad, hungry, sleepy, sleeping, sick, angry, dirty
        case eating, laughing, love, refusing, surprised
    }

    var face: Face = .content
    var breath: CGFloat = 0       // -1...1
    var hop: CGFloat = 0          // points above the floor
    var squash: CGFloat = 0       // + wide, - tall
    var tilt: Angle = .zero
    var blink: CGFloat = 0        // 0 open, 1 closed
    var look = CGPoint.zero       // -1...1 on both axes
    var chew: CGFloat = 0         // 0...1 mouth opening while eating
    var walkPhase: CGFloat = 0    // radians, feet swing when walking
    var wave: CGFloat = 0         // arm swing, 0...1
    var time: Double = 0          // seconds, for small loops (flies, Zzz)
    var tint: CGFloat = 0         // sickly green wash, 0...1
    var shadow = true

    static func still(for mood: Mood) -> PetPose {
        var pose = PetPose()
        pose.face = Face(mood)
        pose.blink = mood == .sleeping ? 1 : 0
        pose.tint = mood == .sick ? 0.5 : 0
        return pose
    }
}

extension PetPose.Face {
    init(_ mood: Mood) {
        switch mood {
        case .happy: self = .happy
        case .content: self = .content
        case .sad: self = .sad
        case .hungry: self = .hungry
        case .sleepy: self = .sleepy
        case .sleeping: self = .sleeping
        case .sick: self = .sick
        case .angry: self = .angry
        case .dirty: self = .dirty
        }
    }
}

// MARK: - Renderer

/// Draws the pet, part by part, into any `GraphicsContext`. Pure drawing: no
/// state, no timers, so the app and the widget share it.
enum PetRenderer {

    static func draw(_ ctx: inout GraphicsContext, in size: CGSize,
                     look: PetAppearance, pose: PetPose, hat: String?) {
        let height = size.height * look.scale
        let width = height * look.aspect
        let floorY = size.height * 0.9
        let breathe = pose.breath * 0.025
        let bodyH = height * (1 + breathe - pose.squash * 0.12)
        let bodyW = width * (1 - breathe * 0.6 + pose.squash * 0.12)
        let centerX = size.width / 2
        let bottom = floorY - pose.hop
        let body = CGRect(x: centerX - bodyW / 2, y: bottom - bodyH, width: bodyW, height: bodyH)

        if pose.shadow { drawShadow(&ctx, centerX: centerX, floorY: floorY, width: width, hop: pose.hop) }

        var layer = ctx
        layer.translateBy(x: centerX, y: bottom)
        layer.rotate(by: pose.tilt)
        layer.translateBy(x: -centerX, y: -bottom)

        drawFeet(&layer, body: body, look: look, pose: pose)
        drawEars(&layer, body: body, look: look, pose: pose, behind: true)
        drawArms(&layer, body: body, look: look, pose: pose)
        drawBody(&layer, body: body, look: look, pose: pose)
        drawEars(&layer, body: body, look: look, pose: pose, behind: false)
        drawMark(&layer, body: body, look: look)
        drawFace(&layer, body: body, look: look, pose: pose)
        if look.isSenior { drawSeniorDetails(&layer, body: body) }
        if let hat { drawHat(&layer, id: hat, body: body, look: look) }
        drawExtras(&layer, body: body, pose: pose, size: size)
    }

    // MARK: Body

    static func bodyPath(_ r: CGRect, taper: CGFloat) -> Path {
        var p = Path()
        let inset = r.width * 0.18 * taper
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.62),
                   control1: CGPoint(x: r.midX + r.width * 0.34 - inset, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.minY + r.height * 0.22))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.06),
                   control2: CGPoint(x: r.midX + r.width * 0.36, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.62),
                   control1: CGPoint(x: r.midX - r.width * 0.36, y: r.maxY),
                   control2: CGPoint(x: r.minX, y: r.maxY - r.height * 0.06))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + r.height * 0.22),
                   control2: CGPoint(x: r.midX - r.width * 0.34 + inset, y: r.minY))
        p.closeSubpath()
        return p
    }

    private static func drawShadow(_ ctx: inout GraphicsContext, centerX: CGFloat,
                                   floorY: CGFloat, width: CGFloat, hop: CGFloat) {
        let shrink = max(0.55, 1 - hop / 160)
        let w = width * 0.9 * shrink
        let rect = CGRect(x: centerX - w / 2, y: floorY - w * 0.07, width: w, height: w * 0.16)
        ctx.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.22 * shrink)))
    }

    private static func drawBody(_ ctx: inout GraphicsContext, body: CGRect,
                                 look: PetAppearance, pose: PetPose) {
        let path = bodyPath(body, taper: look.taper)
        var top = look.top
        var bottom = look.bottom
        if pose.tint > 0 {
            top = top.blended(with: Color(hex: 0xA6D98A), amount: pose.tint * 0.55)
            bottom = bottom.blended(with: Color(hex: 0x6E9E5A), amount: pose.tint * 0.55)
        }
        ctx.fill(path, with: .linearGradient(Gradient(colors: [top, bottom]),
                                             startPoint: CGPoint(x: body.midX - body.width * 0.2, y: body.minY),
                                             endPoint: CGPoint(x: body.midX + body.width * 0.2, y: body.maxY)))

        // Belly patch.
        let belly = CGRect(x: body.midX - body.width * 0.28, y: body.minY + body.height * 0.52,
                           width: body.width * 0.56, height: body.height * 0.42)
        ctx.fill(Path(ellipseIn: belly), with: .color(look.belly.opacity(0.55)))

        // Soft highlight, top left.
        let shine = CGRect(x: body.minX + body.width * 0.18, y: body.minY + body.height * 0.1,
                           width: body.width * 0.26, height: body.height * 0.16)
        ctx.fill(Path(ellipseIn: shine), with: .color(.white.opacity(0.32)))

        ctx.stroke(path, with: .color(.black.opacity(0.12)), lineWidth: max(1, body.width * 0.012))
    }

    private static func drawFeet(_ ctx: inout GraphicsContext, body: CGRect,
                                 look: PetAppearance, pose: PetPose) {
        let footW = body.width * 0.24
        let footH = body.height * 0.12
        for side in [-1.0, 1.0] {
            let swing = sin(pose.walkPhase + (side > 0 ? .pi : 0)) * footH * 0.5
            let rect = CGRect(x: body.midX + side * body.width * 0.2 - footW / 2,
                              y: body.maxY - footH * 0.6 - max(0, swing),
                              width: footW, height: footH)
            ctx.fill(Path(ellipseIn: rect), with: .color(look.bottom.blended(with: .black, amount: 0.18)))
        }
    }

    private static func drawArms(_ ctx: inout GraphicsContext, body: CGRect,
                                 look: PetAppearance, pose: PetPose) {
        let armW = body.width * 0.2
        let armH = body.height * 0.13
        for side in [-1.0, 1.0] {
            var arm = ctx
            let pivot = CGPoint(x: body.midX + side * body.width * 0.44, y: body.minY + body.height * 0.62)
            arm.translateBy(x: pivot.x, y: pivot.y)
            let lift = pose.wave * (side > 0 ? 1 : 0.6) * sin(pose.time * 14)
            arm.rotate(by: .radians(side * (0.35 + Double(lift) * 0.5)))
            let rect = CGRect(x: side > 0 ? -armW * 0.2 : -armW * 0.8, y: -armH / 2, width: armW, height: armH)
            arm.fill(Path(ellipseIn: rect), with: .color(look.bottom.blended(with: .black, amount: 0.08)))
        }
    }

    // MARK: Ears and marks

    private static func drawEars(_ ctx: inout GraphicsContext, body: CGRect,
                                 look: PetAppearance, pose: PetPose, behind: Bool) {
        let color = look.top.blended(with: look.bottom, amount: 0.3)
        let w = body.width
        let top = body.minY
        switch look.ears {
        case .none:
            break
        case .nubs where !behind:
            for side in [-1.0, 1.0] {
                let r = CGRect(x: body.midX + side * w * 0.26 - w * 0.08, y: top + body.height * 0.02,
                               width: w * 0.16, height: w * 0.14)
                ctx.fill(Path(ellipseIn: r), with: .color(color))
            }
        case .cat where behind, .horns where behind:
            let isHorn = look.ears == .horns
            for side in [-1.0, 1.0] {
                var p = Path()
                let baseX = body.midX + side * w * 0.26
                p.move(to: CGPoint(x: baseX - w * 0.12, y: top + body.height * 0.16))
                p.addQuadCurve(to: CGPoint(x: baseX + side * w * (isHorn ? 0.16 : 0.04), y: top - w * (isHorn ? 0.26 : 0.16)),
                               control: CGPoint(x: baseX - side * w * 0.02, y: top - w * 0.02))
                p.addQuadCurve(to: CGPoint(x: baseX + w * 0.12, y: top + body.height * 0.16),
                               control: CGPoint(x: baseX + side * w * 0.1, y: top))
                p.closeSubpath()
                ctx.fill(p, with: .color(isHorn ? Color(hex: 0xE8CFA0) : color))
            }
        case .bunny where behind:
            for side in [-1.0, 1.0] {
                var ear = ctx
                ear.translateBy(x: body.midX + side * w * 0.2, y: top + body.height * 0.12)
                ear.rotate(by: .radians(side * (0.22 + sin(pose.time * 2 + side) * 0.05)))
                let r = CGRect(x: -w * 0.09, y: -w * 0.5, width: w * 0.18, height: w * 0.56)
                ear.fill(Path(ellipseIn: r), with: .color(color))
                ear.fill(Path(ellipseIn: r.insetBy(dx: w * 0.045, dy: w * 0.08)),
                         with: .color(look.cheeks.opacity(0.5)))
            }
        case .antenna where behind:
            for side in [-1.0, 1.0] {
                let base = CGPoint(x: body.midX + side * w * 0.14, y: top + body.height * 0.06)
                let tip = CGPoint(x: base.x + side * w * 0.12 + sin(pose.time * 3) * w * 0.02, y: top - w * 0.24)
                var p = Path()
                p.move(to: base)
                p.addQuadCurve(to: tip, control: CGPoint(x: base.x, y: top - w * 0.1))
                ctx.stroke(p, with: .color(look.bottom), style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
                drawStar(&ctx, center: tip, radius: w * 0.07, color: Color(hex: 0xFFD54A))
            }
        case .leaf where !behind:
            var p = Path()
            let base = CGPoint(x: body.midX, y: top + body.height * 0.03)
            p.move(to: base)
            p.addQuadCurve(to: CGPoint(x: base.x + w * 0.22, y: base.y - w * 0.2),
                           control: CGPoint(x: base.x + w * 0.02, y: base.y - w * 0.24))
            p.addQuadCurve(to: base, control: CGPoint(x: base.x + w * 0.22, y: base.y - w * 0.02))
            ctx.fill(p, with: .color(Color(hex: 0x6CC36A)))
        case .flame where behind:
            var p = Path()
            let flicker = sin(pose.time * 9) * w * 0.02
            p.move(to: CGPoint(x: body.midX - w * 0.2, y: top + body.height * 0.14))
            p.addQuadCurve(to: CGPoint(x: body.midX + flicker, y: top - w * 0.3),
                           control: CGPoint(x: body.midX - w * 0.26, y: top - w * 0.1))
            p.addQuadCurve(to: CGPoint(x: body.midX + w * 0.2, y: top + body.height * 0.14),
                           control: CGPoint(x: body.midX + w * 0.26, y: top - w * 0.06))
            ctx.fill(p, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFE14D), Color(hex: 0xFF5A1F)]),
                                              startPoint: CGPoint(x: body.midX, y: top - w * 0.3),
                                              endPoint: CGPoint(x: body.midX, y: top + body.height * 0.14)))
        case .puffs where behind:
            for (dx, dy, r) in [(-0.3, 0.1, 0.16), (0.3, 0.1, 0.16), (-0.12, -0.02, 0.18), (0.14, -0.02, 0.17)] {
                let c = CGPoint(x: body.midX + w * dx, y: top + body.height * dy)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - w * r, y: c.y - w * r, width: w * r * 2, height: w * r * 2)),
                         with: .color(Color.white.opacity(0.95)))
            }
        default:
            break
        }
    }

    private static func drawMark(_ ctx: inout GraphicsContext, body: CGRect, look: PetAppearance) {
        let w = body.width
        switch look.mark {
        case .none:
            break
        case .star:
            drawStar(&ctx, center: CGPoint(x: body.midX, y: body.minY + body.height * 0.74),
                     radius: w * 0.1, color: Color(hex: 0xFFD54A))
        case .crescent:
            let c = CGPoint(x: body.midX, y: body.minY + body.height * 0.2)
            let outer = Path(ellipseIn: CGRect(x: c.x - w * 0.08, y: c.y - w * 0.08, width: w * 0.16, height: w * 0.16))
            let inner = Path(ellipseIn: CGRect(x: c.x - w * 0.04, y: c.y - w * 0.1, width: w * 0.16, height: w * 0.16))
            ctx.fill(outer.subtracting(inner), with: .color(Color(hex: 0xFFE9A6)))
        case .speckles:
            for (dx, dy) in [(-0.3, 0.3), (0.28, 0.26), (-0.22, 0.8), (0.3, 0.7), (0.05, 0.12)] {
                let c = CGPoint(x: body.midX + w * dx, y: body.minY + body.height * dy)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - w * 0.03, y: c.y - w * 0.025, width: w * 0.06, height: w * 0.05)),
                         with: .color(.black.opacity(0.15)))
            }
        case .rays:
            for i in 0..<5 {
                let angle = Double(i - 2) * 0.42
                var ray = ctx
                ray.translateBy(x: body.midX, y: body.minY + body.height * 0.1)
                ray.rotate(by: .radians(angle))
                let r = CGRect(x: -w * 0.05, y: -w * 0.24, width: w * 0.1, height: w * 0.16)
                ray.fill(Path(ellipseIn: r), with: .color(Color(hex: 0xFF9F1C)))
            }
        }
    }

    static func drawStar(_ ctx: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        ctx.fill(starPath(center: center, radius: radius), with: .color(color))
    }

    static func starPath(center: CGPoint, radius: CGFloat, points: Int = 5) -> Path {
        var p = Path()
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? radius : radius * 0.45
            let a = Double(i) * .pi / Double(points) - .pi / 2
            let pt = CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Colour mixing

extension Color {
    /// Blends toward another colour in sRGB. Good enough for shading.
    func blended(with other: Color, amount: CGFloat) -> Color {
        let a = UIColor(self)
        let b = UIColor(other)
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = max(0, min(1, amount))
        return Color(.sRGB, red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t,
                     blue: b1 + (b2 - b1) * t, opacity: a1 + (a2 - a1) * t)
    }
}
