import SwiftUI

/// Where the built-in furniture sits, as fractions of the room. The stage
/// reads the same numbers to tuck the pet into bed or sit it in the tub.
enum RoomLayout {
    /// The line where the back wall meets the floor.
    static let wallLine: CGFloat = 0.7

    // Bedroom: a bed against the right wall, headboard on the right.
    static let bed = CGRect(x: 0.38, y: 0.62, width: 0.58, height: 0.18)
    static var mattressTop: CGFloat { bed.minY + 0.03 }
    static var bedPetX: CGFloat { bed.minX + bed.width * 0.5 }

    // Bathroom: a tub in the middle of the room.
    static let tub = CGRect(x: 0.16, y: 0.6, width: 0.68, height: 0.25)
    static var tubPetX: CGFloat { tub.midX }

    // Kitchen: a counter along the back wall.
    static let counterTop: CGFloat = 0.55
}

/// The furniture every room comes with, drawn behind the pet.
struct RoomFurniture: View {
    let room: Room

    var body: some View {
        Canvas { ctx, size in
            switch room {
            case .living: Self.drawLiving(&ctx, size)
            case .kitchen: Self.drawKitchen(&ctx, size)
            case .bedroom: Self.drawBedroom(&ctx, size)
            case .bathroom: Self.drawBathroom(&ctx, size)
            case .garden: break
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Living room

    private static func drawLiving(_ ctx: inout GraphicsContext, _ s: CGSize) {
        // A round rug in front of the wall.
        let rug = CGRect(x: s.width * 0.14, y: s.height * 0.8, width: s.width * 0.72, height: s.height * 0.13)
        ctx.fill(Path(ellipseIn: rug), with: .color(Color(hex: 0xE0603A).opacity(0.85)))
        ctx.stroke(Path(ellipseIn: rug.insetBy(dx: rug.width * 0.06, dy: rug.height * 0.16)),
                   with: .color(Color(hex: 0xFFD08A).opacity(0.9)), style: StrokeStyle(lineWidth: 3, dash: [6, 5]))
        // A low shelf under the window.
        let shelf = CGRect(x: s.width * 0.56, y: s.height * 0.56, width: s.width * 0.28, height: s.height * 0.14)
        ctx.fill(Path(roundedRect: shelf, cornerRadius: 6), with: .color(Color(hex: 0x9C6B43)))
        ctx.fill(Path(CGRect(x: shelf.minX, y: shelf.midY - 1.5, width: shelf.width, height: 3)), with: .color(.black.opacity(0.15)))
        for (i, color) in [0x3F7FE0, 0xF99C00, 0x6CC36A].enumerated() {
            let book = CGRect(x: shelf.minX + 8 + CGFloat(i) * 11, y: shelf.minY + 4, width: 8, height: shelf.height * 0.4)
            ctx.fill(Path(roundedRect: book, cornerRadius: 2), with: .color(Color(hex: UInt32(color))))
        }
        let vase = CGRect(x: shelf.maxX - 22, y: shelf.midY + 4, width: 14, height: shelf.height * 0.36)
        ctx.fill(Path(roundedRect: vase, cornerRadius: 5), with: .color(Color(hex: 0x7C4DFF).opacity(0.8)))
    }

    // MARK: Kitchen

    private static func drawKitchen(_ ctx: inout GraphicsContext, _ s: CGSize) {
        let w = s.width, h = s.height
        let top = h * RoomLayout.counterTop
        let wall = h * RoomLayout.wallLine

        // Upper cabinets.
        for i in 0..<3 {
            let cab = CGRect(x: w * (0.32 + CGFloat(i) * 0.2), y: h * 0.06, width: w * 0.18, height: h * 0.2)
            ctx.fill(Path(roundedRect: cab, cornerRadius: 6), with: .color(Color(hex: 0x8FC1A9)))
            ctx.stroke(Path(roundedRect: cab.insetBy(dx: 5, dy: 5), cornerRadius: 4), with: .color(.white.opacity(0.35)), lineWidth: 2)
            ctx.fill(Path(roundedRect: CGRect(x: cab.midX - 8, y: cab.maxY - 12, width: 16, height: 4), cornerRadius: 2),
                     with: .color(Color(hex: 0x4F6B5E)))
        }

        // Fridge on the left.
        let fridge = CGRect(x: w * 0.03, y: h * 0.12, width: w * 0.24, height: wall - h * 0.12 + 4)
        ctx.fill(Path(roundedRect: fridge, cornerRadius: 10), with: .color(Color(hex: 0xEDF3F7)))
        ctx.stroke(Path(roundedRect: fridge, cornerRadius: 10), with: .color(Color(hex: 0xB9C7D2)), lineWidth: 2)
        let split = fridge.minY + fridge.height * 0.36
        ctx.fill(Path(CGRect(x: fridge.minX, y: split, width: fridge.width, height: 2.5)), with: .color(Color(hex: 0xB9C7D2)))
        for y in [split - 26, split + 14] {
            ctx.fill(Path(roundedRect: CGRect(x: fridge.maxX - 12, y: y, width: 5, height: 22), cornerRadius: 2.5),
                     with: .color(Color(hex: 0x9AA8B4)))
        }
        // Magnets.
        ctx.fill(Path(ellipseIn: CGRect(x: fridge.minX + 10, y: fridge.minY + 14, width: 10, height: 10)), with: .color(Color(hex: 0xF99C00)))
        ctx.fill(Path(ellipseIn: CGRect(x: fridge.minX + 26, y: fridge.minY + 22, width: 8, height: 8)), with: .color(Color(hex: 0xE0603A)))

        // Counter with cupboards and an oven.
        let counter = CGRect(x: w * 0.29, y: top, width: w * 0.71, height: wall - top + 4)
        ctx.fill(Path(counter), with: .color(Color(hex: 0xF4E6D0)))
        ctx.fill(Path(roundedRect: CGRect(x: counter.minX - 4, y: top - 7, width: counter.width + 8, height: 9), cornerRadius: 3),
                 with: .color(Color(hex: 0x7A5A44)))
        let oven = CGRect(x: w * 0.5, y: top + 8, width: w * 0.22, height: counter.height - 16)
        ctx.fill(Path(roundedRect: oven, cornerRadius: 5), with: .color(Color(hex: 0x3B3F46)))
        ctx.fill(Path(roundedRect: oven.insetBy(dx: 6, dy: oven.height * 0.3).offsetBy(dx: 0, dy: oven.height * 0.08), cornerRadius: 4),
                 with: .color(Color(hex: 0xFFB24D).opacity(0.35)))
        for i in 0..<3 {
            ctx.fill(Path(ellipseIn: CGRect(x: oven.minX + 8 + CGFloat(i) * 12, y: oven.minY + 5, width: 6, height: 6)),
                     with: .color(.white.opacity(0.6)))
        }
        for x in [w * 0.31, w * 0.75] {
            let door = CGRect(x: x, y: top + 8, width: w * 0.17, height: counter.height - 16)
            ctx.stroke(Path(roundedRect: door, cornerRadius: 4), with: .color(Color(hex: 0xD9C2A2)), lineWidth: 2)
            ctx.fill(Path(roundedRect: CGRect(x: door.midX - 7, y: door.minY + 6, width: 14, height: 3.5), cornerRadius: 2),
                     with: .color(Color(hex: 0x8D6E63)))
        }
        // A pot on the hob.
        let pot = CGRect(x: oven.midX - w * 0.07, y: top - 7 - h * 0.07, width: w * 0.14, height: h * 0.07)
        ctx.fill(Path(roundedRect: pot, cornerRadius: 6), with: .color(Color(hex: 0xD6361C)))
        ctx.fill(Path(roundedRect: CGRect(x: pot.minX - 6, y: pot.minY + 4, width: pot.width + 12, height: 4), cornerRadius: 2),
                 with: .color(Color(hex: 0xA82A16)))
        ctx.fill(Path(roundedRect: CGRect(x: pot.midX - 5, y: pot.minY - 5, width: 10, height: 5), cornerRadius: 2),
                 with: .color(Color(hex: 0xA82A16)))
    }

    // MARK: Bedroom

    private static func drawBedroom(_ ctx: inout GraphicsContext, _ s: CGSize) {
        let w = s.width, h = s.height
        let bed = CGRect(x: RoomLayout.bed.minX * w, y: RoomLayout.bed.minY * h,
                         width: RoomLayout.bed.width * w, height: RoomLayout.bed.height * h)
        let wood = Color(hex: 0x8A5A3B)
        let woodLight = Color(hex: 0xA8703F)

        // Rug beside the bed.
        let rug = CGRect(x: w * 0.04, y: h * 0.82, width: w * 0.4, height: h * 0.11)
        ctx.fill(Path(roundedRect: rug, cornerRadius: rug.height / 2), with: .color(Color(hex: 0x7089D6).opacity(0.75)))
        ctx.stroke(Path(roundedRect: rug.insetBy(dx: 8, dy: 6), cornerRadius: rug.height / 2),
                   with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))

        // Headboard on the right, footboard on the left.
        let head = CGRect(x: bed.maxX - w * 0.05, y: bed.minY - h * 0.16, width: w * 0.05, height: bed.height + h * 0.16 + h * 0.04)
        ctx.fill(Path(roundedRect: head, cornerRadius: 10), with: .color(wood))
        let foot = CGRect(x: bed.minX, y: bed.minY - h * 0.04, width: w * 0.035, height: bed.height + h * 0.08)
        ctx.fill(Path(roundedRect: foot, cornerRadius: 8), with: .color(wood))
        // Frame and legs.
        let frame = CGRect(x: bed.minX, y: bed.minY + bed.height * 0.55, width: bed.width, height: bed.height * 0.32)
        ctx.fill(Path(roundedRect: frame, cornerRadius: 5), with: .color(woodLight))
        // Mattress and sheet.
        let mattress = CGRect(x: bed.minX + w * 0.03, y: bed.minY + h * 0.02, width: bed.width - w * 0.08, height: bed.height * 0.5)
        ctx.fill(Path(roundedRect: mattress, cornerRadius: 10), with: .color(.white))
        ctx.fill(Path(CGRect(x: mattress.minX, y: mattress.maxY - 4, width: mattress.width, height: 4)), with: .color(.black.opacity(0.06)))
        // Pillow by the headboard.
        let pillow = CGRect(x: mattress.maxX - w * 0.13, y: mattress.minY - h * 0.03, width: w * 0.12, height: h * 0.05)
        ctx.fill(Path(roundedRect: pillow, cornerRadius: pillow.height / 2), with: .color(Color(hex: 0xEFF3FF)))
        ctx.stroke(Path(roundedRect: pillow, cornerRadius: pillow.height / 2), with: .color(Color(hex: 0xC8D2EE)), lineWidth: 1.5)
        // The duvet, folded over the end of the bed.
        let duvet = CGRect(x: mattress.minX, y: mattress.minY + mattress.height * 0.3, width: mattress.width * 0.72, height: mattress.height * 0.9)
        ctx.fill(Path(roundedRect: duvet, cornerRadius: 8), with: .color(Color(hex: 0x7089D6)))
        for i in 1..<4 {
            let x = duvet.minX + duvet.width * CGFloat(i) / 4
            ctx.fill(Path(CGRect(x: x, y: duvet.minY + 4, width: 2, height: duvet.height - 8)), with: .color(.white.opacity(0.25)))
        }
        for y in [frame.maxY, frame.maxY] {
            ctx.fill(Path(roundedRect: CGRect(x: bed.minX + 6, y: y - 2, width: 8, height: h * 0.03), cornerRadius: 2), with: .color(wood))
            ctx.fill(Path(roundedRect: CGRect(x: bed.maxX - w * 0.05 - 10, y: y - 2, width: 8, height: h * 0.03), cornerRadius: 2), with: .color(wood))
        }

        // Bedside table with a little lamp, left of the bed.
        let table = CGRect(x: bed.minX - w * 0.16, y: h * 0.58, width: w * 0.12, height: h * RoomLayout.wallLine - h * 0.58 + 4)
        ctx.fill(Path(roundedRect: table, cornerRadius: 5), with: .color(woodLight))
        ctx.fill(Path(roundedRect: CGRect(x: table.midX - 6, y: table.midY, width: 12, height: 3), cornerRadius: 1.5), with: .color(wood))
        let lampBase = CGRect(x: table.midX - 2.5, y: table.minY - h * 0.05, width: 5, height: h * 0.05)
        ctx.fill(Path(lampBase), with: .color(Color(hex: 0x5D4037)))
        var shade = Path()
        shade.move(to: CGPoint(x: table.midX - w * 0.035, y: lampBase.minY))
        shade.addLine(to: CGPoint(x: table.midX + w * 0.035, y: lampBase.minY))
        shade.addLine(to: CGPoint(x: table.midX + w * 0.022, y: lampBase.minY - h * 0.05))
        shade.addLine(to: CGPoint(x: table.midX - w * 0.022, y: lampBase.minY - h * 0.05))
        shade.closeSubpath()
        ctx.fill(shade, with: .color(Color(hex: 0xFFE27A)))
    }

    // MARK: Bathroom

    private static func drawBathroom(_ ctx: inout GraphicsContext, _ s: CGSize) {
        let w = s.width, h = s.height
        let tub = RoomFurniture.tubRect(in: s)

        // Mirror and towel on the wall.
        let mirror = CGRect(x: w * 0.06, y: h * 0.1, width: w * 0.18, height: h * 0.24)
        ctx.fill(Path(roundedRect: mirror, cornerRadius: mirror.width / 2), with: .color(Color(hex: 0xBFE6FF)))
        ctx.stroke(Path(roundedRect: mirror, cornerRadius: mirror.width / 2), with: .color(Color(hex: 0xF4E6D0)), lineWidth: 5)
        var shine = Path()
        shine.move(to: CGPoint(x: mirror.minX + mirror.width * 0.3, y: mirror.minY + mirror.height * 0.25))
        shine.addLine(to: CGPoint(x: mirror.minX + mirror.width * 0.55, y: mirror.minY + mirror.height * 0.12))
        ctx.stroke(shine, with: .color(.white.opacity(0.8)), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        let rail = CGRect(x: w * 0.72, y: h * 0.2, width: w * 0.2, height: 4)
        ctx.fill(Path(roundedRect: rail, cornerRadius: 2), with: .color(Color(hex: 0x9AA8B4)))
        let towel = CGRect(x: rail.minX + 6, y: rail.minY, width: rail.width - 12, height: h * 0.16)
        ctx.fill(Path(roundedRect: towel, cornerRadius: 5), with: .color(Color(hex: 0xFFB24D)))
        ctx.fill(Path(CGRect(x: towel.minX, y: towel.maxY - 12, width: towel.width, height: 4)), with: .color(.white.opacity(0.6)))

        // Shower pipe and head above the tub's tap end.
        let pipeX = tub.maxX - w * 0.06
        ctx.fill(Path(CGRect(x: pipeX, y: h * 0.3, width: 4, height: tub.minY - h * 0.3)), with: .color(Color(hex: 0x9AA8B4)))
        ctx.fill(Path(roundedRect: CGRect(x: pipeX - w * 0.07, y: h * 0.3, width: w * 0.07 + 4, height: 4), cornerRadius: 2),
                 with: .color(Color(hex: 0x9AA8B4)))
        ctx.fill(Path(ellipseIn: CGRect(x: pipeX - w * 0.1, y: h * 0.29, width: w * 0.06, height: h * 0.035)), with: .color(Color(hex: 0x7E8C98)))

        // The back of the tub; its front is drawn by `TubFront`.
        let rim = CGRect(x: tub.minX, y: tub.minY - 6, width: tub.width, height: 14)
        ctx.fill(Path(roundedRect: rim, cornerRadius: 7), with: .color(Color(hex: 0xDDE6EE)))
        ctx.fill(Path(roundedRect: rim.insetBy(dx: 10, dy: 3), cornerRadius: 5), with: .color(Color(hex: 0x9FD3F0)))
        TubFront.drawFront(&ctx, tub: tub)
    }

    static func tubRect(in s: CGSize) -> CGRect {
        CGRect(x: RoomLayout.tub.minX * s.width, y: RoomLayout.tub.minY * s.height,
               width: RoomLayout.tub.width * s.width, height: RoomLayout.tub.height * s.height)
    }
}

/// The front of the bathtub with a crown of foam, drawn over a bathing pet.
struct TubFront: View {
    let foam: Bool

    var body: some View {
        Canvas { ctx, size in
            let tub = RoomFurniture.tubRect(in: size)
            Self.drawFront(&ctx, tub: tub)
            guard foam else { return }
            // Foam along the water line.
            var rng = SplitMix64(seed: 11)
            for i in 0..<16 {
                let x = tub.minX + 10 + (tub.width - 20) * CGFloat(i) / 15
                let r = 9 + CGFloat(rng.next() % 9)
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: tub.minY - r * 0.9, width: r * 2, height: r * 1.7)),
                         with: .color(.white.opacity(0.95)))
            }
        }
        .allowsHitTesting(false)
    }

    static func drawFront(_ ctx: inout GraphicsContext, tub: CGRect) {
        let body = Path(roundedRect: CGRect(x: tub.minX, y: tub.minY, width: tub.width, height: tub.height * 0.86),
                        cornerRadii: RectangleCornerRadii(topLeading: 8, bottomLeading: tub.height * 0.4,
                                                          bottomTrailing: tub.height * 0.4, topTrailing: 8))
        ctx.fill(body, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xD5E0E9)]),
                                             startPoint: CGPoint(x: tub.midX, y: tub.minY), endPoint: CGPoint(x: tub.midX, y: tub.maxY)))
        ctx.fill(Path(roundedRect: CGRect(x: tub.minX, y: tub.minY - 2, width: tub.width, height: 8), cornerRadius: 4),
                 with: .color(Color(hex: 0xEEF3F7)))
        // Clawed feet.
        for x in [tub.minX + tub.width * 0.14, tub.maxX - tub.width * 0.14] {
            ctx.fill(Path(ellipseIn: CGRect(x: x - 9, y: tub.minY + tub.height * 0.8, width: 18, height: tub.height * 0.2)),
                     with: .color(Color(hex: 0xC9A227)))
        }
    }
}

/// The duvet pulled up over a sleeping pet.
struct Duvet: View {
    /// Top edge of the duvet, in the stage's coordinates.
    let top: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let bed = RoomLayout.bed
            let mattressBottom = (bed.minY + 0.02) * h + bed.height * h * 0.5
            let left = (bed.minX + 0.03) * w
            let right = (bed.maxX - 0.05) * w - w * 0.11
            let hem = mattressBottom + bed.height * h * 0.14
            // A soft hump over the pet, falling towards the edges of the bed.
            var path = Path()
            path.move(to: CGPoint(x: left, y: hem))
            path.addLine(to: CGPoint(x: left, y: top + 22))
            path.addQuadCurve(to: CGPoint(x: right, y: top + 18), control: CGPoint(x: (left + right) / 2, y: top - 18))
            path.addLine(to: CGPoint(x: right, y: hem))
            path.addQuadCurve(to: CGPoint(x: left, y: hem), control: CGPoint(x: (left + right) / 2, y: hem + 8))
            ctx.fill(path, with: .linearGradient(Gradient(colors: [Color(hex: 0x8AA0E6), Color(hex: 0x5D74C4)]),
                                                 startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: hem)))
            // The folded hem along the top.
            var fold = Path()
            fold.move(to: CGPoint(x: left, y: top + 22))
            fold.addQuadCurve(to: CGPoint(x: right, y: top + 18), control: CGPoint(x: (left + right) / 2, y: top - 18))
            ctx.stroke(fold, with: .color(Color(hex: 0xEFF3FF)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
            for i in 1..<4 {
                let x = left + (right - left) * CGFloat(i) / 4
                ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: (top + hem) / 2 + 6, width: 6, height: 6)), with: .color(.white.opacity(0.45)))
            }
        }
        .allowsHitTesting(false)
    }
}
