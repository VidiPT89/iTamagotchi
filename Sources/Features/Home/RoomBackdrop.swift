import SwiftUI

/// One room behind the pet: wallpaper, a window onto the real sky, the
/// floor and whatever decor the player has bought for it.
struct RoomBackdrop: View {
    let room: Room
    let wallpaper: String
    let decor: [ShopItem]
    let clock: Date
    let lightsOn: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let floorY = size.height * 0.7
            ZStack(alignment: .topLeading) {
                if room == .garden {
                    SkyView(clock: clock, reduceMotion: reduceMotion)
                    garden(size: size, floorY: floorY)
                } else {
                    WallpaperView(id: wallpaper)
                    window(size: size)
                    floor(size: size, floorY: floorY)
                }
                decorLayer(size: size, floorY: floorY)
                if !lightsOn {
                    LinearGradient(colors: [Color(hex: 0x0B1030).opacity(0.78), Color(hex: 0x05060F).opacity(0.86)],
                                   startPoint: .top, endPoint: .bottom)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: lightsOn)
        }
        .accessibilityHidden(true)
    }

    private func window(size: CGSize) -> some View {
        let w = min(size.width * 0.34, 170)
        let h = w * 1.05
        return ZStack {
            SkyView(clock: clock, reduceMotion: reduceMotion)
            // Frame bars.
            Rectangle().fill(Color(hex: 0xF4E6D0)).frame(width: 5)
            Rectangle().fill(Color(hex: 0xF4E6D0)).frame(height: 5)
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(hex: 0xF4E6D0), lineWidth: 7))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        .position(x: room == .living ? size.width * 0.7 : size.width * 0.3, y: size.height * 0.3)
    }

    private func floor(size: CGSize, floorY: CGFloat) -> some View {
        let wood = room == .bedroom ? [Color(hex: 0xC99466), Color(hex: 0xA8703F)] : [Color(hex: 0xD9A873), Color(hex: 0xB77E48)]
        return ZStack(alignment: .top) {
            LinearGradient(colors: wood, startPoint: .top, endPoint: .bottom)
            // Floorboards.
            Canvas { ctx, s in
                for i in 1..<5 {
                    let y = s.height * CGFloat(i) / 5
                    ctx.fill(Path(CGRect(x: 0, y: y, width: s.width, height: 1.5)), with: .color(.black.opacity(0.08)))
                }
            }
            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 6)
        }
        .frame(width: size.width, height: size.height - floorY)
        .offset(y: floorY)
    }

    private func garden(size: CGSize, floorY: CGFloat) -> some View {
        let daylight = DayCycle.daylight(clock)
        return ZStack(alignment: .top) {
            // Distant hills.
            Ellipse().fill(Color(hex: 0x6FB36A).blended(with: Color(hex: 0x10243A), amount: 1 - daylight))
                .frame(width: size.width * 1.1, height: size.height * 0.34)
                .offset(x: -size.width * 0.3, y: floorY - size.height * 0.14)
            Ellipse().fill(Color(hex: 0x5AA457).blended(with: Color(hex: 0x0D1E30), amount: 1 - daylight))
                .frame(width: size.width, height: size.height * 0.3)
                .offset(x: size.width * 0.35, y: floorY - size.height * 0.1)
            LinearGradient(colors: [Color(hex: 0x7CCB63), Color(hex: 0x4E9B45)].map { $0.blended(with: Color(hex: 0x0E2230), amount: (1 - daylight) * 0.8) },
                           startPoint: .top, endPoint: .bottom)
                .frame(height: size.height - floorY)
                .offset(y: floorY)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func decorLayer(size: CGSize, floorY: CGFloat) -> some View {
        ZStack {
            ForEach(decor) { item in
                let spot = Self.spot(for: item.id)
                // Sized from the shorter side and kept inside the room, so
                // a tall iPad room does not blow the furniture up.
                let glyph = min(size.height, size.width * 1.1) * spot.scale
                let x = min(max(size.width * spot.x, glyph * 0.65), size.width - glyph * 0.65)
                Image(systemName: item.symbol)
                    .font(.system(size: glyph))
                    .foregroundStyle(Self.color(for: item.id))
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
                    .position(x: x, y: spot.onFloor ? floorY - glyph * 0.35 : size.height * spot.y)
            }
        }
    }

    private static func spot(for id: String) -> (x: CGFloat, y: CGFloat, scale: CGFloat, onFloor: Bool) {
        switch id {
        case "decor.plant": return (0.12, 0, 0.12, true)
        case "decor.lamp": return (0.9, 0, 0.26, true)
        case "decor.sofa": return (0.24, 0, 0.16, true)
        case "decor.painting": return (0.24, 0.22, 0.14, false)
        case "decor.books": return (0.86, 0, 0.24, true)
        case "decor.bed": return (0.72, 0, 0.18, true)
        case "decor.teddy": return (0.1, 0, 0.12, true)
        case "decor.tree": return (0.14, 0, 0.34, true)
        case "decor.fish": return (0.84, 0.86, 0.1, false)
        case "decor.tent": return (0.82, 0, 0.22, true)
        default: return (0.5, 0.5, 0.1, false)
        }
    }

    private static func color(for id: String) -> AnyShapeStyle {
        switch id {
        case "decor.plant", "decor.tree": return AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x6CC36A), Color(hex: 0x2E7D32)], startPoint: .top, endPoint: .bottom))
        case "decor.lamp": return AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0x8D6E63)], startPoint: .top, endPoint: .bottom))
        case "decor.sofa": return AnyShapeStyle(Color(hex: 0xE0603A))
        case "decor.painting": return AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xF99C00), Color(hex: 0x7C4DFF)], startPoint: .topLeading, endPoint: .bottomTrailing))
        case "decor.books": return AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x3F7FE0), Color(hex: 0xD6361C)], startPoint: .leading, endPoint: .trailing))
        case "decor.bed": return AnyShapeStyle(Color(hex: 0x7089D6))
        case "decor.teddy": return AnyShapeStyle(Color(hex: 0xB07A4A))
        case "decor.fish": return AnyShapeStyle(Color(hex: 0xFF8A3D))
        case "decor.tent": return AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFB24D), Color(hex: 0xDD7400)], startPoint: .top, endPoint: .bottom))
        default: return AnyShapeStyle(Color.gray)
        }
    }
}

// MARK: - Wallpaper

struct WallpaperView: View {
    let id: String

    var body: some View {
        Canvas { ctx, size in
            let base: [Color]
            switch id {
            case "wall.forest": base = [Color(hex: 0xCFE8C8), Color(hex: 0xA9D39E)]
            case "wall.stars": base = [Color(hex: 0x2D2A5A), Color(hex: 0x4B3F8F)]
            case "wall.dots": base = [Color(hex: 0xFFE3E8), Color(hex: 0xFFC9D4)]
            case "wall.stripes": base = [Color(hex: 0xD9EEFF), Color(hex: 0xB9DDF7)]
            default: base = [Color(hex: 0xFFE9C7), Color(hex: 0xFBD69A)]
            }
            let rect = CGRect(origin: .zero, size: size)
            ctx.fill(Path(rect), with: .linearGradient(Gradient(colors: base), startPoint: .zero,
                                                        endPoint: CGPoint(x: 0, y: size.height)))
            switch id {
            case "wall.stripes":
                var x: CGFloat = 0
                while x < size.width {
                    ctx.fill(Path(CGRect(x: x, y: 0, width: 14, height: size.height)), with: .color(.white.opacity(0.35)))
                    x += 36
                }
            case "wall.dots":
                for row in 0..<Int(size.height / 34) + 1 {
                    for col in 0..<Int(size.width / 34) + 1 {
                        let c = CGPoint(x: CGFloat(col) * 34 + (row.isMultiple(of: 2) ? 0 : 17), y: CGFloat(row) * 34)
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 5, y: c.y - 5, width: 10, height: 10)), with: .color(.white.opacity(0.7)))
                    }
                }
            case "wall.stars":
                var rng = SplitMix64(seed: 7)
                for _ in 0..<40 {
                    let c = CGPoint(x: CGFloat(rng.next() % 1000) / 1000 * size.width, y: CGFloat(rng.next() % 1000) / 1000 * size.height)
                    PetRenderer.drawStar(&ctx, center: c, radius: CGFloat(3 + rng.next() % 5), color: Color(hex: 0xFCBB00).opacity(0.8))
                }
            case "wall.forest":
                for i in 0..<9 {
                    let x = CGFloat(i) / 8 * size.width
                    var tree = Path()
                    tree.move(to: CGPoint(x: x, y: size.height * 0.25))
                    tree.addLine(to: CGPoint(x: x + 26, y: size.height * 0.62))
                    tree.addLine(to: CGPoint(x: x - 26, y: size.height * 0.62))
                    tree.closeSubpath()
                    ctx.fill(tree, with: .color(Color(hex: 0x6BAF62).opacity(0.45)))
                }
            default:
                // Classic: a soft wainscot line.
                ctx.fill(Path(CGRect(x: 0, y: size.height * 0.52, width: size.width, height: 4)), with: .color(Color(hex: 0xE8B86A).opacity(0.6)))
            }
        }
    }
}

// MARK: - Sky

/// A live sky: daylight follows the clock, the sun and moon move across,
/// stars come out at night and the weather drifts by.
struct SkyView: View {
    let clock: Date
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            Canvas { ctx, size in
                draw(&ctx, size: size, t: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: TimeInterval) {
        let daylight = DayCycle.daylight(clock)
        let weather = Weather.at(clock)
        let overcast = weather == .sunny ? 0.0 : 0.35
        let dayTop = Color(hex: 0x5BB8F5).blended(with: Color(hex: 0x9AA7B4), amount: overcast)
        let dayBottom = Color(hex: 0xBFE6FF).blended(with: Color(hex: 0xC9D1D9), amount: overcast)
        let top = Color(hex: 0x0B1033).blended(with: dayTop, amount: daylight)
        var bottom = Color(hex: 0x2A2360).blended(with: dayBottom, amount: daylight)
        if daylight > 0, daylight < 1 { bottom = bottom.blended(with: Color(hex: 0xFFB36B), amount: 0.5) }
        let rect = CGRect(origin: .zero, size: size)
        ctx.fill(Path(rect), with: .linearGradient(Gradient(colors: [top, bottom]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

        if daylight < 0.6 {
            var rng = SplitMix64(seed: 99)
            for i in 0..<30 {
                let c = CGPoint(x: CGFloat(rng.next() % 1000) / 1000 * size.width, y: CGFloat(rng.next() % 1000) / 1000 * size.height * 0.6)
                let twinkle = 0.5 + 0.5 * sin(t * 2 + Double(i))
                let alpha = (1 - daylight / 0.6) * twinkle
                ctx.fill(Path(ellipseIn: CGRect(x: c.x, y: c.y, width: 2.2, height: 2.2)), with: .color(.white.opacity(alpha)))
            }
        }

        // Sun by day, moon by night, on an arc across the sky.
        let phase = DayCycle.phase(clock)
        let isDay = daylight > 0.05
        let arc = isDay ? (phase - 0.25) * 2 : ((phase + 0.25).truncatingRemainder(dividingBy: 1)) * 2
        let x = size.width * CGFloat(max(0, min(1, arc)))
        let y = size.height * (0.62 - 0.45 * CGFloat(sin(max(0, min(1, arc)) * .pi)))
        let r = min(size.width, size.height) * 0.1
        if isDay {
            ctx.fill(Path(ellipseIn: CGRect(x: x - r * 1.8, y: y - r * 1.8, width: r * 3.6, height: r * 3.6)),
                     with: .radialGradient(Gradient(colors: [Color(hex: 0xFFE27A).opacity(0.6), .clear]),
                                           center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r * 1.8))
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0xFFD54A)))
        } else {
            let moon = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            let bite = Path(ellipseIn: CGRect(x: x - r * 0.4, y: y - r * 1.2, width: r * 2, height: r * 2))
            ctx.fill(moon.subtracting(bite), with: .color(Color(hex: 0xFFF3C4)))
        }

        if weather != .sunny || daylight > 0.5 {
            let count = weather == .sunny ? 2 : 4
            for i in 0..<count {
                let speed = 8 + Double(i) * 3
                let cx = CGFloat((t * speed + Double(i) * 170).truncatingRemainder(dividingBy: Double(size.width) + 160)) - 80
                let cy = size.height * (0.12 + 0.12 * CGFloat(i % 3))
                drawCloud(&ctx, at: CGPoint(x: cx, y: cy), width: size.width * 0.32,
                          color: weather == .rainy ? Color(hex: 0xAEB7C2) : .white, alpha: 0.35 + 0.55 * daylight)
            }
        }

        if weather == .rainy || weather == .snowy {
            var rng = SplitMix64(seed: 3)
            for _ in 0..<40 {
                let x0 = CGFloat(rng.next() % 1000) / 1000 * size.width
                let speed = weather == .rainy ? 260.0 : 40.0
                let offset = Double(rng.next() % 1000)
                let y = CGFloat((t * speed + offset).truncatingRemainder(dividingBy: Double(size.height) + 20)) - 10
                if weather == .rainy {
                    ctx.fill(Path(CGRect(x: x0, y: y, width: 1.6, height: 9)), with: .color(Color(hex: 0xCFE3FF).opacity(0.8)))
                } else {
                    let sway = CGFloat(sin(t + offset)) * 6
                    ctx.fill(Path(ellipseIn: CGRect(x: x0 + sway, y: y, width: 4, height: 4)), with: .color(.white.opacity(0.9)))
                }
            }
        }
    }

    private func drawCloud(_ ctx: inout GraphicsContext, at c: CGPoint, width w: CGFloat, color: Color, alpha: Double) {
        var cloud = Path()
        for (dx, dy, r) in [(-0.3, 0.05, 0.2), (0, -0.08, 0.26), (0.3, 0.04, 0.2), (0.12, 0.1, 0.2), (-0.12, 0.1, 0.2)] {
            cloud.addEllipse(in: CGRect(x: c.x + w * dx - w * r, y: c.y + w * dy - w * r * 0.7, width: w * r * 2, height: w * r * 1.4))
        }
        ctx.fill(cloud, with: .color(color.opacity(alpha)))
    }
}
