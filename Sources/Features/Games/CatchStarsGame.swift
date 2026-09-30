import CoreMotion
import SpriteKit
import SwiftUI

/// Stars fall, the pet catches them. Drag to move, or tilt the device.
/// Rain clouds cost points. Thirty seconds on the clock.
final class CatchStarsScene: SKScene {

    var onScore: ((Int) -> Void)?
    var onTime: ((Int) -> Void)?
    var onFinish: ((Int) -> Void)?
    var onCatch: ((Bool) -> Void)?

    private let pet = SKSpriteNode()
    private var petTexture: SKTexture?
    private var targetX: CGFloat?
    private var score = 0
    private var remaining: TimeInterval = 30
    private var lastUpdate: TimeInterval = 0
    private var spawnTimer: TimeInterval = 0
    private var running = false
    private let motion = CMMotionManager()

    init(size: CGSize, petImage: UIImage?) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        if let petImage { petTexture = SKTexture(image: petImage) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func didMove(to view: SKView) {
        guard pet.parent == nil else { return }
        pet.texture = petTexture
        pet.size = CGSize(width: 110, height: 110)
        pet.position = CGPoint(x: size.width / 2, y: 90)
        addChild(pet)
        if motion.isAccelerometerAvailable {
            motion.accelerometerUpdateInterval = 1 / 60
            motion.startAccelerometerUpdates()
        }
        run(.sequence([.wait(forDuration: 0.8), .run { [weak self] in self?.running = true }]))
    }

    override func willMove(from view: SKView) {
        motion.stopAccelerometerUpdates()
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : min(0.05, currentTime - lastUpdate)
        lastUpdate = currentTime
        guard running else { return }

        let before = Int(ceil(remaining))
        remaining -= dt
        if Int(ceil(remaining)) != before { onTime?(max(0, Int(ceil(remaining)))) }
        if remaining <= 0 {
            running = false
            motion.stopAccelerometerUpdates()
            onFinish?(score)
            return
        }

        movePet(dt: dt)
        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawn()
            // Faster as time runs out.
            spawnTimer = 0.35 + remaining / 30 * 0.45
        }
        checkCatches()
    }

    private func movePet(dt: TimeInterval) {
        var x = pet.position.x
        if let targetX {
            x += (targetX - x) * min(1, CGFloat(dt) * 14)
        } else if let data = motion.accelerometerData {
            x += CGFloat(data.acceleration.x) * 900 * CGFloat(dt)
        }
        x = max(50, min(size.width - 50, x))
        let lean = (x - pet.position.x) * 0.02
        pet.position.x = x
        pet.zRotation = -max(-0.3, min(0.3, lean))
    }

    private func spawn() {
        let bad = Int.random(in: 0..<100) < 22
        let golden = !bad && Int.random(in: 0..<100) < 12
        let node: SKNode
        if bad {
            let cloud = SKLabelNode(text: "🌧️")
            cloud.fontSize = 42
            cloud.verticalAlignmentMode = .center
            cloud.name = "cloud"
            node = cloud
        } else {
            let star = SKShapeNode(path: PetRenderer.starPath(center: .zero, radius: golden ? 22 : 16).cgPath)
            star.fillColor = UIColor(Color(hex: golden ? 0xFFE27A : 0xFCBB00))
            star.strokeColor = UIColor(Color(hex: 0xDD7400))
            star.lineWidth = 2
            star.glowWidth = golden ? 4 : 0
            star.name = golden ? "gold" : "star"
            star.run(.repeatForever(.rotate(byAngle: .pi, duration: 1.2)))
            node = star
        }
        node.position = CGPoint(x: .random(in: 30...(max(31, size.width - 30))), y: size.height + 30)
        addChild(node)
        let fall = SKAction.moveTo(y: -40, duration: .random(in: 2.2...3.4) * (0.6 + remaining / 30 * 0.4))
        node.run(.sequence([fall, .removeFromParent()]))
    }

    private func checkCatches() {
        let catchZone = CGRect(x: pet.position.x - 50, y: pet.position.y - 20, width: 100, height: 80)
        for node in children where node !== pet && node.name != nil {
            guard catchZone.contains(node.position) else { continue }
            let good = node.name != "cloud"
            score = max(0, score + (node.name == "gold" ? 3 : good ? 1 : -3))
            onScore?(score)
            onCatch?(good)
            burst(at: node.position, good: good)
            node.removeFromParent()
            pet.run(.sequence([.scale(to: good ? 1.15 : 0.85, duration: 0.08), .scale(to: 1, duration: 0.12)]))
        }
    }

    private func burst(at point: CGPoint, good: Bool) {
        for _ in 0..<8 {
            let dot = SKShapeNode(circleOfRadius: 4)
            dot.fillColor = good ? UIColor(Color(hex: 0xFCBB00)) : UIColor(Color(hex: 0x8FB3D9))
            dot.strokeColor = .clear
            dot.position = point
            addChild(dot)
            let v = CGVector(dx: .random(in: -60...60), dy: .random(in: 10...80))
            dot.run(.sequence([.group([.move(by: v, duration: 0.45), .fadeOut(withDuration: 0.45)]), .removeFromParent()]))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        targetX = touches.first?.location(in: self).x
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        targetX = touches.first?.location(in: self).x
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        targetX = nil
    }
}

struct CatchStarsGame: View {
    let finish: (Int, Bool) -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @State private var scene: CatchStarsScene?
    @State private var score = 0
    @State private var time = 30

    /// A pet left standing in the middle catches about a dozen on its own.
    static let goal = 20

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                SkyView(clock: Date(), reduceMotion: true).ignoresSafeArea()
                if let scene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                }
                VStack(spacing: 8) {
                    HStack(spacing: 14) {
                        label("star.fill", "\(score) / \(Self.goal)")
                        label("timer", model.t("stars.time", time))
                    }
                    Text(model.t("stars.hint"))
                        .font(.rounded(13, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(.black.opacity(0.3), in: Capsule())
                }
                .padding(.top, 76)
                .allowsHitTesting(false)
            }
            .onAppear { makeScene(size: geo.size) }
        }
    }

    private func label(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.rounded(18, .heavy))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.black.opacity(0.35), in: Capsule())
    }

    private func makeScene(size: CGSize) {
        guard scene == nil else { return }
        let renderer = ImageRenderer(content:
            Canvas { ctx, s in
                var pose = PetPose()
                pose.face = .happy
                pose.shadow = false
                PetRenderer.draw(&ctx, in: s, look: PetAppearance.of(stage: model.pet.stage, form: model.pet.form),
                                 pose: pose, hat: model.household.hat)
            }
            .frame(width: 220, height: 220))
        renderer.scale = 2
        let scene = CatchStarsScene(size: size, petImage: renderer.uiImage)
        scene.onScore = { value in score = value }
        scene.onTime = { value in time = value }
        scene.onCatch = { good in
            model.audio.play(good ? .star : .miss)
            model.haptics.play(good ? .tap : .warning)
        }
        scene.onFinish = { value in finish(value, value >= Self.goal) }
        self.scene = scene
    }
}
