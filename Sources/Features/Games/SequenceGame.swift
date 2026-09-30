import SwiftUI

/// Watch the pads light up, then repeat the pattern. Each round adds one
/// more step; one wrong tap ends the game.
struct SequenceGame: View {
    let finish: (Int, Bool) -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    static let startLength = 3
    static let winningLength = 6
    static let maxLength = 10

    private let pads: [(symbol: String, color: UInt32, sound: Sound)] = [
        ("star.fill", 0xFCBB00, .padC), ("heart.fill", 0xFF4F7B, .padE),
        ("moon.fill", 0x7C6CFF, .padG), ("leaf.fill", 0x3DD68C, .padHigh),
    ]

    @State private var sequence: [Int] = []
    @State private var input = 0
    @State private var lit: Int?
    @State private var watching = true
    @State private var bestLength = 0
    @State private var reaction: Reaction?
    @State private var over = false

    var body: some View {
        VStack(spacing: 18) {
            Text(model.t(watching ? "seq.watch" : "seq.repeat"))
                .font(.rounded(24, .heavy))
                .foregroundStyle(palette.text)
                .padding(.top, 70)
                .contentTransition(.opacity)
                .animation(.easeInOut, value: watching)
            Text(model.t("seq.length", max(sequence.count, Self.startLength)))
                .font(.rounded(15, .bold))
                .foregroundStyle(palette.textDim)

            PetView(stage: model.pet.stage, form: model.pet.form, mood: .happy,
                    hat: model.household.hat, reaction: reaction)
                .frame(width: 150, height: 150)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(pads.indices, id: \.self) { i in pad(i) }
            }
            .frame(maxWidth: 380)
            .padding(.horizontal, 24)
            Spacer()
        }
        .onAppear { nextRound() }
    }

    private func pad(_ i: Int) -> some View {
        let on = lit == i
        let color = Color(hex: pads[i].color)
        return Button { tap(i) } label: {
            Image(systemName: pads[i].symbol)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(color.opacity(on ? 1 : 0.45), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: color.opacity(on ? 0.8 : 0), radius: 18)
                .scaleEffect(on ? 1.06 : 1)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: on)
        }
        .buttonStyle(.plain)
        .disabled(watching || over)
        .accessibilityLabel(Text(model.t("seq.pad.\(i)")))
    }

    // MARK: Flow

    private func nextRound() {
        if sequence.isEmpty {
            sequence = (0..<Self.startLength).map { _ in Int.random(in: 0..<pads.count) }
        } else {
            sequence.append(Int.random(in: 0..<pads.count))
        }
        input = 0
        watching = true
        for (step, pad) in sequence.enumerated() {
            let start = 0.8 + Double(step) * 0.6
            DispatchQueue.main.asyncAfter(deadline: .now() + start) { flash(pad) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(sequence.count) * 0.6) {
            watching = false
        }
    }

    private func flash(_ i: Int) {
        lit = i
        model.audio.play(pads[i].sound)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { if lit == i { lit = nil } }
    }

    private func tap(_ i: Int) {
        guard !watching, !over else { return }
        flash(i)
        model.haptics.play(.tap)
        guard sequence[input] == i else {
            over = true
            model.audio.play(.miss)
            model.haptics.play(.warning)
            reaction = Reaction(face: .refusing, until: Date().addingTimeInterval(1))
            let reached = bestLength
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                finish(reached * 10, reached >= Self.winningLength)
            }
            return
        }
        input += 1
        guard input == sequence.count else { return }
        bestLength = sequence.count
        if bestLength >= Self.maxLength {
            over = true
            finish(bestLength * 10, true)
            return
        }
        reaction = Reaction(face: .laughing, until: Date().addingTimeInterval(0.8))
        model.audio.play(.star)
        watching = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { nextRound() }
    }
}
