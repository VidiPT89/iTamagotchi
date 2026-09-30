import SwiftUI

/// The opening title card: an egg wobbles, cracks and bursts into the
/// wordmark, then the credits fade in. It leaves on its own, or on a tap.
struct SplashView: View {
    let onFinish: () -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    @State private var eggVisible = false
    @State private var wobble = false
    @State private var cracks = 0
    @State private var burst = false
    @State private var showWordmark = false
    @State private var showTagline = false
    @State private var showCredit = false
    @State private var showLinks = false
    @State private var finished = false

    private let particles: [(angle: Double, distance: CGFloat, size: CGFloat)] = (0..<22).map(Self.particle)

    private nonisolated static func particle(_ i: Int) -> (angle: Double, distance: CGFloat, size: CGFloat) {
        let angle = Double(i) / 22 * 2 * .pi + Double(i % 3) * 0.2
        let distance = CGFloat(90 + (i * 37) % 90)
        let size = CGFloat(6 + (i * 5) % 9)
        return (angle, distance, size)
    }

    var body: some View {
        ZStack {
            Color(hex: 0x0A0A0F).ignoresSafeArea()
            RadialGradient(colors: [Color(hex: 0xF99C00).opacity(burst ? 0.42 : 0.22), .clear],
                           center: .center, startRadius: 0, endRadius: burst ? 420 : 260)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 1), value: burst)

            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    particleBurst
                    egg
                    wordmark
                }
                .frame(height: 220)

                Text(model.t("splash.tagline"))
                    .font(.rounded(15, .medium))
                    .kerning(1.2)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline || reduceMotion ? 0 : 8)
                    .padding(.top, 8)

                Spacer()
                credits.padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: Text(model.t("a11y.skipSplash"))) { finish() }
        .onAppear(perform: run)
        .environment(\.colorScheme, .dark)
    }

    // MARK: Pieces

    private var egg: some View {
        Canvas { ctx, size in
            PetRenderer.drawEgg(&ctx, in: size, wobble: .zero, cracks: cracks, glow: 0.8)
        }
        .frame(width: 150, height: 180)
        .rotationEffect(.degrees(wobble ? 7 : -7), anchor: .bottom)
        .scaleEffect(burst ? 1.5 : (eggVisible ? 1 : 0.4))
        .opacity(burst ? 0 : (eggVisible ? 1 : 0))
        .animation(.easeIn(duration: 0.25), value: burst)
        .accessibilityHidden(true)
    }

    private var particleBurst: some View {
        ZStack {
            ForEach(particles.indices, id: \.self) { i in
                let p = particles[i]
                Image(systemName: i.isMultiple(of: 3) ? "sparkle" : "star.fill")
                    .font(.system(size: p.size, weight: .bold))
                    .foregroundStyle(i.isMultiple(of: 2) ? Color(hex: 0xFCBB00) : Color(hex: 0xF99C00))
                    .offset(x: burst ? cos(p.angle) * p.distance * 1.6 : 0,
                            y: burst ? sin(p.angle) * p.distance : 0)
                    .opacity(burst ? 0 : 1)
                    .scaleEffect(burst ? 1 : 0.2)
                    .animation(.easeOut(duration: 1.3).delay(Double(i % 5) * 0.03), value: burst)
            }
        }
        .opacity(eggVisible ? 1 : 0)
        .accessibilityHidden(true)
    }

    private var wordmark: some View {
        HStack(spacing: 0) {
            Text("i").foregroundStyle(.white)
            Text("Tamagotchi")
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFCBB00), Color(hex: 0xF99C00), Color(hex: 0xDD7400)],
                                                startPoint: .leading, endPoint: .trailing))
        }
        .font(.rounded(52, .heavy))
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .shadow(color: Color(hex: 0xF99C00).opacity(0.6), radius: 24)
        .scaleEffect(showWordmark ? 1 : 0.6)
        .opacity(showWordmark ? 1 : 0)
        .accessibilityAddTraits(.isHeader)
    }

    private var credits: some View {
        VStack(spacing: 14) {
            Text(model.t("about.developedBy"))
                .font(.rounded(15, .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .opacity(showCredit ? 1 : 0)
                .offset(y: showCredit || reduceMotion ? 0 : 12)

            VStack(spacing: 8) {
                link("ividi.dev", symbol: "globe", url: Links.website, label: model.t("a11y.openWebsite"))
                link("github.com/VidiPT89", symbol: "chevron.left.forwardslash.chevron.right",
                     url: Links.github, label: model.t("a11y.openGitHub"))
            }
            .opacity(showLinks ? 1 : 0)
            .offset(y: showLinks || reduceMotion ? 0 : 12)
        }
    }

    private func link(_ title: String, symbol: String, url: URL, label: String) -> some View {
        Button { openURL(url) } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 12, weight: .bold))
                Text(title).font(.rounded(14, .semibold))
            }
            .foregroundStyle(Color(hex: 0xF99C00))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(hex: 0xF99C00).opacity(0.1), in: Capsule())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(Text(label))
    }

    // MARK: Choreography

    private func run() {
        guard !reduceMotion else {
            showWordmark = true
            showTagline = true
            showCredit = true
            showLinks = true
            after(2.2) { finish() }
            return
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { eggVisible = true }
        withAnimation(.easeInOut(duration: 0.14).repeatCount(9, autoreverses: true).delay(0.3)) { wobble = true }
        for step in 1...3 {
            after(0.35 + Double(step) * 0.28) {
                cracks = step
                model.audio.play(.crack)
                model.haptics.play(.crack)
            }
        }
        after(1.4) {
            burst = true
            model.audio.play(.hatch)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) { showWordmark = true }
        }
        after(1.7) { withAnimation(.easeOut(duration: 0.5)) { showTagline = true } }
        after(2.0) { withAnimation(.easeOut(duration: 0.5)) { showCredit = true } }
        after(2.3) { withAnimation(.easeOut(duration: 0.5)) { showLinks = true } }
        after(4.2) { finish() }
    }

    private func after(_ delay: TimeInterval, _ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            work()
        }
    }

    /// Guarded, because the timer and a tap can both arrive.
    private func finish() {
        guard !finished else { return }
        finished = true
        onFinish()
    }
}
