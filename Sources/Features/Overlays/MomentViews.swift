import SwiftUI

// MARK: - Evolution

/// A glowing silhouette pulses, the screen flashes, and the new shape is revealed.
struct EvolutionView: View {
    let stage: LifeStage
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = 0
    @State private var pulse = false
    @State private var spin = false

    var body: some View {
        let pet = model.pet
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
            rays.opacity(phase >= 1 ? 1 : 0.4)

            VStack(spacing: 20) {
                Text(model.t("evolution.title"))
                    .font(.rounded(30, .heavy))
                    .foregroundStyle(.white)
                ZStack {
                    if phase < 2 {
                        PetView(stage: previousStage, form: nil, mood: .content)
                            .brightness(1)
                            .scaleEffect(pulse ? 1.08 : 0.9)
                            .transition(.opacity)
                    } else {
                        ConfettiRing(active: !reduceMotion)
                        PetView(stage: pet.stage, form: pet.form, mood: .happy, hat: model.household.hat,
                                reaction: Reaction(face: .laughing, until: Date().addingTimeInterval(1.5)))
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }
                }
                .frame(width: 240, height: 240)

                if phase >= 2 {
                    VStack(spacing: 10) {
                        Text(model.t("evolution.became", pet.name, revealName))
                            .font(.rounded(22, .bold))
                            .foregroundStyle(palette.primaryLight)
                            .multilineTextAlignment(.center)
                        if let form = pet.form, stage == .adult {
                            if form.isRare {
                                Label(model.t("evolution.rare"), systemImage: "sparkles")
                                    .font(.rounded(13, .heavy))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 12).padding(.vertical, 5)
                                    .background(Color(hex: 0xFCBB00), in: Capsule())
                            }
                            Text(model.t("form.\(form.rawValue).trait"))
                                .font(.rounded(15, .medium))
                                .foregroundStyle(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                        }
                        PrimaryButton(title: model.t("common.continue")) {
                            withAnimation(.easeInOut(duration: 0.4)) { model.evolvedTo = nil }
                        }
                        .padding(.top, 10)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(28)

            Color.white.opacity(phase == 1 ? 1 : 0).ignoresSafeArea().allowsHitTesting(false)
        }
        .environment(\.colorScheme, .dark)
        .onAppear(perform: run)
    }

    private var previousStage: LifeStage {
        LifeStage.allCases.last { $0 < stage && $0 != .egg } ?? .baby
    }

    private var revealName: String {
        if stage == .adult, let form = model.pet.form { return model.t("form.\(form.rawValue)") }
        return model.t("stage.\(stage.rawValue)")
    }

    private var rays: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<14 {
                var p = Path()
                let a = Double(i) / 14 * 2 * .pi
                let spread = 0.09
                p.move(to: c)
                p.addLine(to: CGPoint(x: c.x + cos(a - spread) * 900, y: c.y + sin(a - spread) * 900))
                p.addLine(to: CGPoint(x: c.x + cos(a + spread) * 900, y: c.y + sin(a + spread) * 900))
                p.closeSubpath()
                ctx.fill(p, with: .color(Color(hex: i.isMultiple(of: 2) ? 0xF99C00 : 0xFCBB00).opacity(0.18)))
            }
        }
        .rotationEffect(.degrees(spin ? 360 : 0))
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func run() {
        if !reduceMotion {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 0.3).repeatCount(7, autoreverses: true)) { pulse = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.3 : 2.1)) {
            withAnimation(.easeIn(duration: 0.15)) { phase = 1 }
            model.haptics.play(.evolve)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                model.audio.play(.win)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { phase = 2 }
            }
        }
    }
}

// MARK: - Farewell

/// A gentle goodbye: the pet floats up into a starry sky, towards its planet.
struct FarewellView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rise = false

    var body: some View {
        let pet = model.pet
        ZStack {
            LinearGradient(colors: [Color(hex: 0x05060F), Color(hex: 0x1B1640), Color(hex: 0x3A2A5E)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Canvas { ctx, size in
                var rng = SplitMix64(seed: 42)
                for _ in 0..<80 {
                    let c = CGPoint(x: CGFloat(rng.next() % 1000) / 1000 * size.width,
                                    y: CGFloat(rng.next() % 1000) / 1000 * size.height)
                    let r = CGFloat(rng.next() % 3) * 0.6 + 0.8
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x, y: c.y, width: r, height: r)), with: .color(.white.opacity(0.8)))
                }
                let planet = CGRect(x: size.width * 0.62, y: size.height * 0.08, width: 70, height: 70)
                ctx.fill(Path(ellipseIn: planet), with: .linearGradient(
                    Gradient(colors: [Color(hex: 0xFCBB00), Color(hex: 0xDD7400)]),
                    startPoint: planet.origin, endPoint: CGPoint(x: planet.maxX, y: planet.maxY)))
                ctx.stroke(Path(ellipseIn: planet.insetBy(dx: -18, dy: 24)), with: .color(Color(hex: 0xFFE27A).opacity(0.7)), lineWidth: 3)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)

            VStack(spacing: 18) {
                Spacer()
                PetView(stage: pet.stage, form: pet.form, mood: .sleeping, hat: model.household.hat)
                    .frame(width: 180, height: 180)
                    .offset(y: rise ? -60 : 40)
                    .opacity(rise ? 0.85 : 1)
                    .shadow(color: Color(hex: 0xFCBB00).opacity(0.6), radius: 30)
                Text(model.t("farewell.title", pet.name))
                    .font(.rounded(30, .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(model.t(pet.farewell == .neglect ? "farewell.neglect" : "farewell.oldAge", pet.name))
                    .font(.rounded(16, .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
                Text(model.t("farewell.lived", model.duration(pet.age)))
                    .font(.rounded(14, .bold))
                    .foregroundStyle(Color(hex: 0xFCBB00))
                Spacer()
                PrimaryButton(title: model.t("farewell.newEgg"), symbol: "oval.portrait.fill") {
                    withAnimation(.easeInOut(duration: 0.6)) { model.startNewEgg() }
                }
            }
            .padding(28)
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { rise = true }
        }
    }
}

// MARK: - Away summary

struct AwaySummaryView: View {
    let summary: AwaySummary
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            palette.backdrop
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SheetHeader(title: model.t("away.title")) { dismiss() }
                        .padding(.horizontal, -20)
                    Text(model.t("away.duration", model.duration(summary.duration)))
                        .font(.rounded(16, .semibold))
                        .foregroundStyle(palette.primary)

                    VStack(alignment: .leading, spacing: 10) {
                        if summary.lines.isEmpty {
                            Text(model.t("away.nothing")).foregroundStyle(palette.textDim)
                        }
                        ForEach(summary.lines, id: \.self) { line in
                            Label(line, systemImage: "sparkle")
                                .foregroundStyle(palette.text)
                        }
                    }
                    .font(.rounded(15, .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    Text(model.t("away.needs"))
                        .font(.rounded(17, .bold))
                        .foregroundStyle(palette.text)
                    VStack(spacing: 10) {
                        ForEach(NeedKind.allCases) { kind in
                            let before = Int(summary.before[kind])
                            let after = Int(summary.after[kind])
                            HStack {
                                Image(systemName: kind.symbol).foregroundStyle(palette.primary).frame(width: 22)
                                Text(model.t("need.\(kind.rawValue)")).foregroundStyle(palette.text)
                                Spacer()
                                Text("\(before)").foregroundStyle(palette.textDim)
                                Image(systemName: "arrow.right").font(.caption).foregroundStyle(palette.textFaint)
                                Text("\(after)")
                                    .foregroundStyle(kind == .discipline ? palette.accent : palette.needColor(Double(after)))
                                    .fontWeight(.bold)
                            }
                            .font(.rounded(15, .medium))
                            .monospacedDigit()
                        }
                    }
                    .card()
                    PrimaryButton(title: model.t("common.ok")) { dismiss() }
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
    }
}
