import SwiftUI

/// The living pet: a Canvas redrawn every frame with a procedural pose.
/// Breathing, blinking, bouncing, gaze and reactions are all computed here
/// from the clock, so nothing drifts or piles up.
struct PetView: View {
    let stage: LifeStage
    let form: AdultForm?
    let mood: Mood
    var hat: String?
    var reaction: Reaction?
    /// Where the finger is, in this view's coordinates.
    var gaze: CGPoint?
    var walking = false
    var direction: CGFloat = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let pose = makePose(at: timeline.date, size: size)
                PetRenderer.draw(&ctx, in: size, look: PetAppearance.of(stage: stage, form: form),
                                 pose: pose, hat: hat)
            }
        }
    }

    private func makePose(at date: Date, size: CGSize) -> PetPose {
        let t = date.timeIntervalSinceReferenceDate
        var pose = PetPose()
        pose.time = t
        if let reaction, reaction.until > date {
            pose.face = reaction.face
        } else {
            pose.face = PetPose.Face(mood)
        }
        pose.tint = pose.face == .sick ? 0.6 : 0

        let sleeping = pose.face == .sleeping
        pose.breath = CGFloat(sin(t * 2 * .pi * (sleeping ? 0.22 : 0.5)))
        pose.blink = sleeping ? 1 : blink(at: t)
        pose.look = look(at: t, size: size)

        let motion: CGFloat = reduceMotion ? 0 : 1
        switch pose.face {
        case .eating:
            pose.chew = CGFloat(abs(sin(t * 9)))
            pose.squash = pose.chew * 0.25 * motion
        case .laughing:
            let hop = CGFloat(abs(sin(t * 10)))
            pose.hop = hop * 12 * motion
            pose.squash = (0.3 - hop * 0.5) * motion
            pose.wave = 1
        case .love:
            pose.hop = CGFloat(abs(sin(t * 6))) * 6 * motion
            pose.tilt = .degrees(sin(t * 5) * 5 * Double(motion))
            pose.wave = 0.6
        case .angry:
            pose.tilt = .degrees(sin(t * 24) * 3 * Double(motion))
            pose.hop = CGFloat(abs(sin(t * 12))) * 4 * motion
        case .refusing:
            pose.tilt = .degrees(sin(t * 18) * 8 * Double(motion))
        default:
            let lively = CGFloat(mood.liveliness)
            // A lively pet does a little hop every couple of seconds.
            let cycle = t.truncatingRemainder(dividingBy: 2.4)
            if cycle < 0.5, lively > 0.3 {
                let jump = CGFloat(sin(cycle / 0.5 * .pi))
                pose.hop = jump * 16 * lively * motion
                pose.squash = -jump * 0.3 * motion
            } else if cycle < 0.62, lively > 0.3 {
                pose.squash = CGFloat(sin((cycle - 0.5) / 0.12 * .pi)) * 0.35 * lively * motion
            }
            pose.tilt = .degrees(sin(t * 0.9) * 2.5 * Double(lively + 0.2) * Double(motion))
            pose.wave = pose.face == .happy ? 0.35 : 0
        }

        if walking, !reduceMotion {
            pose.walkPhase = CGFloat(t * 12)
            pose.hop = max(pose.hop, CGFloat(abs(sin(t * 12))) * 5)
            pose.tilt = .degrees(sin(t * 12) * 4 + Double(direction) * 3)
        }
        return pose
    }

    /// Blinks at irregular intervals, with the odd double blink.
    private func blink(at t: TimeInterval) -> CGFloat {
        let period = 3.7
        let index = floor(t / period)
        let offset = (sin(index * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
        let local = t - index * period - abs(offset) * 1.5
        let length = 0.16
        if local >= 0, local < length { return CGFloat(sin(local / length * .pi)) }
        if index.truncatingRemainder(dividingBy: 3) == 0, local >= 0.24, local < 0.24 + length {
            return CGFloat(sin((local - 0.24) / length * .pi))
        }
        return 0
    }

    private func look(at t: TimeInterval, size: CGSize) -> CGPoint {
        if let gaze {
            let eye = CGPoint(x: size.width / 2, y: size.height * 0.55)
            let dx = (gaze.x - eye.x) / max(1, size.width * 0.6)
            let dy = (gaze.y - eye.y) / max(1, size.height * 0.6)
            return CGPoint(x: max(-1, min(1, dx)), y: max(-1, min(1, dy)))
        }
        guard !reduceMotion else { return .zero }
        return CGPoint(x: sin(t * 0.37) * 0.55 + (walking ? direction * 0.6 : 0), y: sin(t * 0.23) * 0.3)
    }
}

/// A little pile on the floor, with stink lines.
struct PoopView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let w = size.width
                let brown = Color(hex: 0x8A5A2B)
                for (i, layer) in [(0.0, 1.0), (0.22, 0.74), (0.4, 0.48)].enumerated() {
                    let lw = w * 0.8 * layer.1
                    let rect = CGRect(x: w / 2 - lw / 2, y: size.height * (0.72 - layer.0), width: lw, height: size.height * 0.26)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: rect.height / 2),
                             with: .color(brown.blended(with: .white, amount: CGFloat(i) * 0.08)))
                }
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.3, y: size.height * 0.62, width: w * 0.12, height: w * 0.1)),
                         with: .color(.white.opacity(0.4)))
                for i in 0..<2 {
                    var line = Path()
                    let x = w * (0.35 + CGFloat(i) * 0.3)
                    let sway = CGFloat(sin(t * 3 + Double(i))) * w * 0.05
                    line.move(to: CGPoint(x: x, y: size.height * 0.28))
                    line.addQuadCurve(to: CGPoint(x: x + sway, y: 0), control: CGPoint(x: x - w * 0.12, y: size.height * 0.14))
                    ctx.stroke(line, with: .color(Color(hex: 0x7BA05B).opacity(0.7)),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
            }
        }
    }
}
