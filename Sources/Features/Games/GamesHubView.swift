import SwiftUI

enum MiniGame: String, CaseIterable, Identifiable {
    case leftRight, catchStars, rhythm, sequence
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .leftRight: return "arrow.left.arrow.right"
        case .catchStars: return "star.fill"
        case .rhythm: return "music.note"
        case .sequence: return "square.grid.2x2.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .leftRight: return [Color(hex: 0xFCBB00), Color(hex: 0xF99C00)]
        case .catchStars: return [Color(hex: 0x7C6CFF), Color(hex: 0x3F2FC0)]
        case .rhythm: return [Color(hex: 0xFF6B8B), Color(hex: 0xD6365C)]
        case .sequence: return [Color(hex: 0x5BE0A0), Color(hex: 0x1F9D5C)]
        }
    }
}

struct GamesHubView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var playing: MiniGame?

    var body: some View {
        ZStack {
            palette.backdrop
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SheetHeader(title: model.t("games.title")) { dismiss() }
                        .padding(.horizontal, -20)
                    Text(model.t("games.subtitle"))
                        .font(.rounded(15, .medium))
                        .foregroundStyle(palette.textDim)
                    ForEach(MiniGame.allCases) { game in
                        Button {
                            if model.canPlay { playing = game } else { model.perform(.played(won: false)) }
                        } label: { card(for: game) }
                        .buttonStyle(PressableStyle(scale: 0.97))
                    }
                }
                .padding(20)
            }
        }
        #if DEBUG
        .onAppear {
            if let raw = UserDefaults.standard.string(forKey: "qaGame") { playing = MiniGame(rawValue: raw) }
        }
        #endif
        .fullScreenCover(item: $playing) { game in
            GameContainer(game: game)
                .themed()
                .environment(model)
        }
    }

    private func card(for game: MiniGame) -> some View {
        HStack(spacing: 16) {
            Image(systemName: game.symbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(LinearGradient(colors: game.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: game.colors[1].opacity(0.4), radius: 10, y: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.t("game.\(game.rawValue)")).font(.rounded(18, .bold)).foregroundStyle(palette.text)
                Text(model.t("game.\(game.rawValue).desc")).font(.rounded(13, .medium)).foregroundStyle(palette.textDim)
                    .multilineTextAlignment(.leading)
                Label(model.t("games.energyCost"), systemImage: "bolt.fill")
                    .font(.rounded(11, .bold))
                    .foregroundStyle(palette.primary)
            }
            Spacer()
            Image(systemName: "play.circle.fill").font(.system(size: 30)).foregroundStyle(palette.primary)
        }
        .card()
    }
}

/// Runs one game, then shows the result with the coins it paid.
struct GameContainer: View {
    let game: MiniGame
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var result: (score: Int, won: Bool, coins: Int)?
    @State private var round = 0

    var body: some View {
        ZStack {
            palette.backdrop
            if let result {
                GameResultView(score: result.score, won: result.won, coins: result.coins,
                               canReplay: model.canPlay,
                               onReplay: {
                                   withAnimation(.spring) { self.result = nil; round += 1 }
                               },
                               onClose: { dismiss() })
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else {
                Group {
                    switch game {
                    case .leftRight: LeftRightGame(finish: finish)
                    case .catchStars: CatchStarsGame(finish: finish)
                    case .rhythm: RhythmGame(finish: finish)
                    case .sequence: SequenceGame(finish: finish)
                    }
                }
                .id(round)
                .overlay(alignment: .topTrailing) {
                    IconButton(symbol: "xmark", label: model.t("common.close")) { dismiss() }
                        .padding(16)
                }
            }
        }
    }

    private func finish(score: Int, won: Bool) {
        let coins = model.finishGame(score: score, won: won)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { result = (score, won, coins) }
    }
}

struct GameResultView: View {
    let score: Int
    let won: Bool
    let coins: Int
    let canReplay: Bool
    let onReplay: () -> Void
    let onClose: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                if won { ConfettiRing(active: true) }
                PetView(stage: model.pet.stage, form: model.pet.form, mood: won ? .happy : .content,
                        hat: model.household.hat,
                        reaction: Reaction(face: won ? .laughing : .content, until: Date().addingTimeInterval(1.5)))
                    .frame(width: 180, height: 180)
            }
            Text(model.t(won ? "game.win" : "game.lose"))
                .font(.rounded(36, .heavy))
                .foregroundStyle(palette.warmGradient)
            Text(model.t("game.score", score))
                .font(.rounded(18, .semibold))
                .foregroundStyle(palette.textDim)
            HStack(spacing: 8) {
                CoinPill(coins: model.household.coins)
                Text(model.t("game.coins", coins))
                    .font(.rounded(17, .bold))
                    .foregroundStyle(palette.success)
            }
            Spacer()
            if canReplay {
                PrimaryButton(title: model.t("common.playAgain"), symbol: "arrow.clockwise", action: onReplay)
            }
            Button(model.t("common.close"), action: onClose)
                .font(.rounded(17, .bold))
                .foregroundStyle(palette.textDim)
                .buttonStyle(.pressable)
                .padding(.bottom, 12)
        }
        .padding(24)
    }
}

// MARK: - Left or Right

struct LeftRightGame: View {
    let finish: (Int, Bool) -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    private let rounds = 5
    @State private var round = 1
    @State private var correct = 0
    @State private var looking: CGFloat?
    @State private var verdict: Bool?
    @State private var busy = false

    var body: some View {
        VStack(spacing: 22) {
            Text(model.t("lr.round", round, rounds))
                .font(.rounded(15, .bold))
                .foregroundStyle(palette.textDim)
                .padding(.top, 70)
            Text(model.t("lr.prompt"))
                .font(.rounded(26, .heavy))
                .foregroundStyle(palette.text)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                ForEach(0..<rounds, id: \.self) { i in
                    Image(systemName: i < correct ? "star.fill" : "star")
                        .foregroundStyle(palette.primaryLight)
                        .symbolEffect(.bounce, value: correct)
                }
            }
            Spacer()
            ZStack {
                PetView(stage: model.pet.stage, form: model.pet.form, mood: .content, hat: model.household.hat,
                        reaction: verdict.map { Reaction(face: $0 ? .laughing : .refusing, until: Date().addingTimeInterval(1)) },
                        gaze: looking.map { CGPoint(x: $0 < 0 ? -400 : 800, y: 130) })
                    .frame(width: 260, height: 260)
                    .rotation3DEffect(.degrees(Double(looking ?? 0) * 22), axis: (x: 0, y: 1, z: 0))
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: looking)
                if let verdict {
                    Text(model.t(verdict ? "lr.correct" : "lr.wrong"))
                        .font(.rounded(24, .heavy))
                        .foregroundStyle(verdict ? palette.success : palette.danger)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(.regularMaterial, in: Capsule())
                        .offset(y: -150)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            Spacer()
            HStack(spacing: 16) {
                choice(-1, "arrow.left", "lr.left")
                choice(1, "arrow.right", "lr.right")
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
    }

    private func choice(_ side: CGFloat, _ symbol: String, _ key: String) -> some View {
        Button { guess(side) } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 30, weight: .heavy))
                Text(model.t(key)).font(.rounded(16, .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(palette.warmGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: palette.primary.opacity(0.35), radius: 12, y: 5)
        }
        .buttonStyle(.pressable)
        .disabled(busy)
    }

    private func guess(_ side: CGFloat) {
        busy = true
        let actual: CGFloat = Bool.random() ? -1 : 1
        looking = actual
        let hit = actual == side
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { verdict = hit }
            if hit { correct += 1 }
            model.audio.play(hit ? .star : .miss)
            model.haptics.play(hit ? .success : .warning)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeInOut(duration: 0.25)) {
                verdict = nil
                looking = nil
            }
            if round >= rounds {
                finish(correct * 10, correct >= 3)
            } else {
                round += 1
                busy = false
            }
        }
    }
}
