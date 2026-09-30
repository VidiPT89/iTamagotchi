import SwiftUI

/// Circles shrink towards a ring; tap as they meet it. Timing is judged
/// against the clock, not the frame, so it is fair at any frame rate.
struct RhythmGame: View {
    let finish: (Int, Bool) -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    private static let approach: TimeInterval = 1.2
    private static let pattern: [Double] = [0, 0.7, 1.4, 2.1, 2.45, 2.8, 3.5, 4.2, 4.55, 4.9, 5.6, 6.3, 6.65, 7.0, 7.7, 8.4]
    static let winningScore = 100

    @State private var start = Date().addingTimeInterval(2)
    @State private var judged: [Int: Judgement] = [:]
    @State private var score = 0
    @State private var lastJudgement: Judgement?
    @State private var flash = 0
    @State private var done = false

    enum Judgement: Equatable {
        case perfect, good, miss
        var points: Int { self == .perfect ? 10 : self == .good ? 5 : 0 }
        var key: String { self == .perfect ? "rhythm.perfect" : self == .good ? "rhythm.good" : "rhythm.miss" }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            ZStack {
                VStack(spacing: 10) {
                    Text(model.t("game.score", score))
                        .font(.rounded(22, .heavy))
                        .foregroundStyle(palette.text)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(score)))
                    if elapsed < 0 {
                        Text(model.t("game.ready")).font(.rounded(18, .bold)).foregroundStyle(palette.primary)
                    } else if let lastJudgement {
                        Text(model.t(lastJudgement.key))
                            .font(.rounded(22, .heavy))
                            .foregroundStyle(lastJudgement == .miss ? palette.danger : palette.success)
                            .id(flash)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                }
                .padding(.top, 70)

                ring(elapsed: elapsed)

                VStack {
                    Spacer()
                    PetView(stage: model.pet.stage, form: model.pet.form, mood: .happy, hat: model.household.hat,
                            reaction: lastJudgement.map { Reaction(face: $0 == .miss ? .refusing : .laughing, until: Date().addingTimeInterval(0.4)) })
                        .frame(width: 150, height: 150)
                        .padding(.bottom, 24)
                }
            }
            .onChange(of: Int(elapsed * 20)) { _, _ in expireMissed(elapsed: elapsed) }
        }
        .contentShape(Rectangle())
        .onTapGesture { tap() }
        .accessibilityAddTraits(.allowsDirectInteraction)
    }

    private func ring(elapsed: TimeInterval) -> some View {
        ZStack {
            Circle()
                .stroke(palette.primary, lineWidth: 8)
                .frame(width: 120, height: 120)
                .shadow(color: palette.primary.opacity(0.6), radius: 12)
            Text(model.t("rhythm.tap"))
                .font(.rounded(22, .heavy))
                .foregroundStyle(palette.primary)
            ForEach(Self.pattern.indices, id: \.self) { i in
                let until = Self.pattern[i] - elapsed
                if judged[i] == nil, until > -0.2, until < Self.approach {
                    let scale = 1 + max(0, until) / Self.approach * 1.8
                    Circle()
                        .stroke(palette.primaryLight.opacity(0.9), lineWidth: 6)
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .opacity(min(1, (Self.approach - until) / 0.3))
                }
            }
        }
    }

    private func tap() {
        let elapsed = Date().timeIntervalSince(start)
        guard elapsed > -0.3, !done else { return }
        let candidates = Self.pattern.indices.filter { judged[$0] == nil }
        guard let index = candidates.min(by: { abs(Self.pattern[$0] - elapsed) < abs(Self.pattern[$1] - elapsed) }) else { return }
        let offset = abs(Self.pattern[index] - elapsed)
        guard offset < 0.35 else {
            model.audio.play(.miss)
            return
        }
        let judgement: Judgement = offset < 0.08 ? .perfect : offset < 0.18 ? .good : .miss
        record(judgement, for: index)
    }

    private func expireMissed(elapsed: TimeInterval) {
        for i in Self.pattern.indices where judged[i] == nil && Self.pattern[i] - elapsed < -0.2 {
            record(.miss, for: i)
        }
    }

    private func record(_ judgement: Judgement, for index: Int) {
        judged[index] = judgement
        score += judgement.points
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            lastJudgement = judgement
            flash += 1
        }
        model.audio.play(judgement == .miss ? .miss : .hit)
        model.haptics.play(judgement == .miss ? .warning : .tap)
        if judged.count == Self.pattern.count, !done {
            done = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                finish(score, score >= Self.winningScore)
            }
        }
    }
}
