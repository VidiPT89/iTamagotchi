import SpriteKit
import SwiftUI

enum EffectKind {
    case hearts, bubbles, confetti, stars, sparkles, crumbs, evolution
}

/// A transparent SpriteKit layer over the room. It only plays short-lived
/// particles; the pet itself is drawn by SwiftUI underneath.
final class EffectsScene: SKScene {

    private var textures: [String: SKTexture] = [:]
    var reduceMotion = false

    override init(size: CGSize = CGSize(width: 400, height: 400)) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = .zero
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// `point` is in SwiftUI coordinates (origin top-left).
    func play(_ kind: EffectKind, at point: CGPoint) {
        guard size.height > 0 else { return }
        let origin = CGPoint(x: point.x, y: size.height - point.y)
        let scale: CGFloat = reduceMotion ? 0.4 : 1
        switch kind {
        case .hearts: burst(count: Int(7 * scale) + 1, texture: heart(), colors: [0xFF4F7B, 0xFF8FB8, 0xFF3D6E], at: origin, rise: 150, spread: 70, size: 22)
        case .bubbles: burst(count: Int(14 * scale) + 1, texture: bubble(), colors: [0xBDE8FF, 0xFFFFFF, 0x9FD8FF], at: origin, rise: 170, spread: 110, size: 24)
        case .confetti: confetti(at: origin, count: Int(40 * scale) + 4)
        case .stars: burst(count: Int(9 * scale) + 1, texture: star(), colors: [0xFCBB00, 0xFFE27A, 0xF99C00], at: origin, rise: 120, spread: 120, size: 22)
        case .sparkles: burst(count: Int(10 * scale) + 1, texture: star(points: 4), colors: [0xFFFFFF, 0xFCBB00], at: origin, rise: 90, spread: 100, size: 16)
        case .crumbs: burst(count: Int(8 * scale) + 1, texture: circle(), colors: [0xE8B06A, 0xC98A3F], at: origin, rise: -30, spread: 60, size: 7)
        case .evolution: evolution(at: origin)
        }
    }

    // MARK: - Emitters

    private func burst(count: Int, texture: SKTexture, colors: [UInt32], at origin: CGPoint,
                       rise: CGFloat, spread: CGFloat, size: CGFloat) {
        for i in 0..<count {
            let node = SKSpriteNode(texture: texture)
            let s = size * CGFloat.random(in: 0.6...1.2)
            node.size = CGSize(width: s, height: s)
            node.color = UIColor(Color(hex: colors[i % colors.count]))
            node.colorBlendFactor = 1
            node.alpha = 0
            node.position = CGPoint(x: origin.x + .random(in: -20...20), y: origin.y + .random(in: -10...10))
            node.setScale(0.3)
            addChild(node)

            let duration = TimeInterval.random(in: 0.9...1.5)
            let target = CGPoint(x: node.position.x + .random(in: -spread...spread),
                                 y: node.position.y + rise * .random(in: 0.6...1.2))
            let move = SKAction.move(to: target, duration: duration)
            move.timingMode = .easeOut
            let appear = SKAction.group([.fadeIn(withDuration: 0.12), .scale(to: 1, duration: 0.25)])
            let wobble = SKAction.rotate(byAngle: .random(in: -0.8...0.8), duration: duration)
            let vanish = SKAction.sequence([.wait(forDuration: duration * 0.6), .fadeOut(withDuration: duration * 0.4)])
            node.run(.sequence([.wait(forDuration: Double(i) * 0.03),
                                .group([appear, move, wobble, vanish]),
                                .removeFromParent()]))
        }
    }

    private func confetti(at origin: CGPoint, count: Int) {
        let palette: [UInt32] = [0xF99C00, 0xFCBB00, 0xFF4F7B, 0x3DD68C, 0x6EC6FF, 0x9C8CFF]
        for i in 0..<count {
            let node = SKSpriteNode(color: UIColor(Color(hex: palette[i % palette.count])),
                                    size: CGSize(width: .random(in: 6...10), height: .random(in: 10...16)))
            node.position = origin
            addChild(node)
            let angle = CGFloat.random(in: 0.2...(.pi - 0.2))
            let power = CGFloat.random(in: 160...300)
            let peak = CGPoint(x: origin.x + cos(angle) * power, y: origin.y + sin(angle) * power)
            let fall = CGPoint(x: peak.x + .random(in: -40...40), y: peak.y - .random(in: 200...320))
            let up = SKAction.move(to: peak, duration: 0.45)
            up.timingMode = .easeOut
            let down = SKAction.move(to: fall, duration: 1.3)
            down.timingMode = .easeIn
            let spin = SKAction.repeatForever(.rotate(byAngle: .pi * 2, duration: .random(in: 0.4...0.9)))
            node.run(spin)
            node.run(.sequence([up, .group([down, .sequence([.wait(forDuration: 0.8), .fadeOut(withDuration: 0.5)])]),
                                .removeFromParent()]))
        }
    }

    private func evolution(at origin: CGPoint) {
        // Rotating rays of light behind the pet.
        let rays = SKNode()
        rays.position = origin
        rays.alpha = 0
        addChild(rays)
        for i in 0..<12 {
            let ray = SKShapeNode(rectOf: CGSize(width: 14, height: max(size.width, size.height)), cornerRadius: 7)
            ray.fillColor = UIColor(Color(hex: i.isMultiple(of: 2) ? 0xFCBB00 : 0xF99C00)).withAlphaComponent(0.35)
            ray.strokeColor = .clear
            ray.zRotation = CGFloat(i) * .pi / 6
            rays.addChild(ray)
        }
        rays.run(.sequence([
            .group([.fadeIn(withDuration: 0.4), .rotate(byAngle: .pi, duration: 2.4)]),
            .fadeOut(withDuration: 0.5),
            .removeFromParent(),
        ]))

        let flash = SKShapeNode(circleOfRadius: max(size.width, size.height))
        flash.position = origin
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0
        addChild(flash)
        flash.run(.sequence([.wait(forDuration: 1.2), .fadeAlpha(to: 0.9, duration: 0.15),
                             .fadeOut(withDuration: 0.6), .removeFromParent()]))

        run(.sequence([.wait(forDuration: 1.3), .run { [weak self] in
            self?.play(.stars, at: CGPoint(x: origin.x, y: (self?.size.height ?? 0) - origin.y))
            self?.confetti(at: origin, count: 36)
        }]))
    }

    // MARK: - Textures

    private func texture(_ key: String, draw: (CGContext, CGSize) -> Void) -> SKTexture {
        if let cached = textures[key] { return cached }
        let size = CGSize(width: 64, height: 64)
        let image = UIGraphicsImageRenderer(size: size).image { draw($0.cgContext, size) }
        let tex = SKTexture(image: image)
        textures[key] = tex
        return tex
    }

    private func heart() -> SKTexture {
        texture("heart") { ctx, _ in
            ctx.addPath(PetRenderer.heartPath(center: CGPoint(x: 32, y: 34), size: 56).cgPath)
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillPath()
        }
    }

    private func star(points: Int = 5) -> SKTexture {
        texture("star\(points)") { ctx, _ in
            ctx.addPath(PetRenderer.starPath(center: CGPoint(x: 32, y: 32), radius: 30, points: points).cgPath)
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillPath()
        }
    }

    private func circle() -> SKTexture {
        texture("circle") { ctx, _ in
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 4, y: 4, width: 56, height: 56))
        }
    }

    private func bubble() -> SKTexture {
        texture("bubble") { ctx, _ in
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(5)
            ctx.strokeEllipse(in: CGRect(x: 6, y: 6, width: 52, height: 52))
            ctx.setFillColor(UIColor.white.withAlphaComponent(0.25).cgColor)
            ctx.fillEllipse(in: CGRect(x: 6, y: 6, width: 52, height: 52))
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 18, y: 16, width: 12, height: 9))
        }
    }
}
