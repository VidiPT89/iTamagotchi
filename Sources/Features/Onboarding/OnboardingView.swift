import SwiftUI

/// First launch: choose a language, tap the egg until it hatches, name the
/// baby. After a farewell only the egg and the name are asked again.
struct OnboardingView: View {
    let askLanguage: Bool

    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Step { case language, egg, name }

    @State private var step: Step
    @State private var taps = 0
    @State private var wobble = false
    @State private var hatched = false
    @State private var name = ""
    @FocusState private var nameFocused: Bool

    init(askLanguage: Bool) {
        self.askLanguage = askLanguage
        _step = State(initialValue: askLanguage ? .language : .egg)
    }

    private let tapsToHatch = 5
    private let suggestions = ["Pipo", "Tico", "Nico", "Bolinha", "Mochi", "Kiko", "Lumi", "Fofo", "Pixel", "Tofu", "Biscoito", "Zuzu"]

    var body: some View {
        VStack(spacing: 24) {
            switch step {
            case .language: languageStep.transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            case .egg: eggStep.transition(.move(edge: .trailing).combined(with: .opacity))
            case .name: nameStep.transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .padding(24)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Language

    private var languageStep: some View {
        VStack(spacing: 28) {
            Spacer()
            Canvas { ctx, size in
                PetRenderer.drawEgg(&ctx, in: size, wobble: .zero, cracks: 0, glow: 0.6)
            }
            .frame(width: 120, height: 150)
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(model.t("onboarding.welcome"))
                    .font(.rounded(30, .heavy))
                    .foregroundStyle(palette.text)
                    .multilineTextAlignment(.center)
                Text(model.t("onboarding.chooseLanguage"))
                    .font(.rounded(17, .medium))
                    .foregroundStyle(palette.textDim)
            }

            HStack(spacing: 14) {
                ForEach(AppLanguage.allCases) { lang in
                    let selected = model.language == lang
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { model.preferences.language = lang }
                    } label: {
                        VStack(spacing: 8) {
                            Text(lang.flag).font(.system(size: 40))
                            Text(lang.nativeName).font(.rounded(16, .bold))
                            Text(lang.label).font(.rounded(12, .heavy)).opacity(0.7)
                        }
                        .foregroundStyle(selected ? .white : palette.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(selected ? AnyShapeStyle(palette.warmGradient) : AnyShapeStyle(palette.surface),
                                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(palette.stroke))
                    }
                    .buttonStyle(.pressable)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            Spacer()
            PrimaryButton(title: model.t("common.continue"), symbol: "arrow.right") {
                model.finishOnboarding(language: model.language)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = .egg }
            }
        }
    }

    // MARK: Egg

    private var eggStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(model.t(askLanguage ? "onboarding.eggTitle" : "onboarding.newEggTitle"))
                .font(.rounded(28, .heavy))
                .foregroundStyle(palette.text)
                .multilineTextAlignment(.center)

            Button(action: tapEgg) {
                Canvas { ctx, size in
                    PetRenderer.drawEgg(&ctx, in: size, wobble: .zero,
                                        cracks: min(3, taps * 3 / tapsToHatch + (taps > 0 ? 1 : 0)),
                                        glow: 0.3 + CGFloat(taps) / CGFloat(tapsToHatch) * 0.6)
                }
                .frame(width: 200, height: 250)
                .rotationEffect(.degrees(wobble ? 9 : -9), anchor: .bottom)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.08).repeatCount(3, autoreverses: true), value: wobble)
                .scaleEffect(1 + CGFloat(taps) * 0.03)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(Text(model.t("onboarding.tapEgg")))

            Text(model.t("onboarding.tapEgg"))
                .font(.rounded(16, .medium))
                .foregroundStyle(palette.textDim)

            HStack(spacing: 8) {
                ForEach(0..<tapsToHatch, id: \.self) { i in
                    Capsule().fill(i < taps ? palette.primary : palette.text.opacity(0.12))
                        .frame(width: 26, height: 6)
                }
            }
            .animation(.spring(response: 0.3), value: taps)
            Spacer()
        }
    }

    private func tapEgg() {
        taps += 1
        wobble.toggle()
        model.audio.play(.crack)
        model.haptics.play(.crack)
        guard taps >= tapsToHatch else { return }
        model.audio.play(.hatch)
        model.haptics.play(.success)
        name = suggestions.randomElement() ?? ""
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            hatched = true
            step = .name
        }
    }

    // MARK: Name

    private var nameStep: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(palette.primary.opacity(0.18)).frame(width: 230, height: 230).blur(radius: 30)
                ConfettiRing(active: hatched && !reduceMotion)
                PetView(stage: .baby, form: nil, mood: .happy,
                        reaction: Reaction(face: .laughing, until: Date().addingTimeInterval(2)))
                    .frame(width: 200, height: 200)
            }
            Text(model.t("onboarding.hatched"))
                .font(.rounded(34, .heavy))
                .foregroundStyle(palette.warmGradient)
            Text(model.t("onboarding.nameTitle"))
                .font(.rounded(18, .semibold))
                .foregroundStyle(palette.textDim)

            HStack(spacing: 10) {
                TextField(model.t("onboarding.namePlaceholder"), text: $name)
                    .font(.rounded(22, .bold))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit(begin)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(palette.primary.opacity(0.5), lineWidth: 1.5))
                    .onChange(of: name) { _, new in if new.count > 14 { name = String(new.prefix(14)) } }
                Button {
                    name = suggestions.filter { $0 != name }.randomElement() ?? name
                    model.audio.play(.tap)
                } label: {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(palette.primary)
                        .frame(width: 56, height: 56)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(Text(model.t("onboarding.randomName")))
            }
            Spacer()
            PrimaryButton(title: model.t("onboarding.begin"), symbol: "heart.fill",
                          enabled: !name.trimmingCharacters(in: .whitespaces).isEmpty, action: begin)
        }
    }

    private func begin() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        nameFocused = false
        withAnimation(.easeInOut(duration: 0.5)) { model.hatch(named: name) }
    }
}

/// Stars flung out in a ring, used whenever something is born or grows.
struct ConfettiRing: View {
    let active: Bool
    @State private var fire = false

    var body: some View {
        ZStack {
            ForEach(0..<18, id: \.self) { i in
                let angle = Double(i) / 18 * 2 * .pi
                Image(systemName: i.isMultiple(of: 2) ? "star.fill" : "sparkle")
                    .font(.system(size: CGFloat(8 + i % 3 * 4), weight: .bold))
                    .foregroundStyle(i.isMultiple(of: 3) ? Color(hex: 0xFF4F7B) : Color(hex: 0xFCBB00))
                    .offset(x: fire ? cos(angle) * 150 : 0, y: fire ? sin(angle) * 150 : 0)
                    .opacity(fire ? 0 : 1)
                    .scaleEffect(fire ? 1.2 : 0.3)
            }
        }
        .onAppear {
            guard active else { return }
            withAnimation(.easeOut(duration: 1.4)) { fire = true }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
