import SwiftUI

// MARK: - Typography

extension Font {
    /// SF Rounded that follows the reader's text size, capped so the
    /// game layouts still fit at the largest accessibility sizes.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(for: size)
        return .system(size: min(scaled, size * 1.4), weight: weight, design: .rounded)
    }
}

// MARK: - Buttons

/// Every tappable thing in the app squashes a little and ticks the haptics.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.92

    func makeBody(configuration: Configuration) -> some View {
        PressableBody(configuration: configuration, scale: scale)
    }

    private struct PressableBody: View {
        let configuration: Configuration
        let scale: CGFloat
        @Environment(AppModel.self) private var model

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? scale : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
                .onChange(of: configuration.isPressed) { _, pressed in
                    if pressed { model.haptics.play(.tap) }
                }
        }
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

/// The big warm call-to-action capsule.
struct PrimaryButton: View {
    let title: String
    var symbol: String?
    var enabled = true
    let action: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .font(.rounded(18, .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .frame(maxWidth: 360)
            .background(palette.warmGradient, in: Capsule())
            .shadow(color: palette.primary.opacity(0.45), radius: 16, y: 6)
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(.pressable)
        .disabled(!enabled)
    }
}

/// A round glassy icon button for toolbars.
struct IconButton: View {
    let symbol: String
    let label: String
    var badge = false
    let action: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(palette.text)
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(palette.stroke))
                .overlay(alignment: .topTrailing) {
                    if badge {
                        Circle().fill(palette.danger).frame(width: 10, height: 10)
                            .overlay(Circle().stroke(palette.background, lineWidth: 2))
                    }
                }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(Text(label))
    }
}

// MARK: - Surfaces

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(palette.stroke))
            .shadow(color: .black.opacity(palette.isDark ? 0.35 : 0.06), radius: 14, y: 6)
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View { modifier(CardModifier(padding: padding)) }
}

// MARK: - Coins

struct CoinPill: View {
    let coins: Int
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0xE0A100)],
                                             startPoint: .top, endPoint: .bottom))
                Text("¢").font(.rounded(12, .heavy)).foregroundStyle(Color(hex: 0x7A4A00))
            }
            .frame(width: 20, height: 20)
            Text("\(coins)")
                .font(.rounded(16, .bold))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(coins)))
                .foregroundStyle(palette.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(palette.stroke))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: coins)
    }
}

// MARK: - Need ring

struct NeedRing: View {
    let kind: NeedKind
    let value: Double
    var size: CGFloat = 46
    var label: String
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        let color = kind == .discipline ? palette.accent : palette.needColor(value)
        ZStack {
            Circle().stroke(palette.text.opacity(0.08), lineWidth: size * 0.12)
            Circle()
                .trim(from: 0, to: max(0.02, value / 100))
                .stroke(AngularGradient(colors: [color.opacity(0.7), color], center: .center),
                        style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.7, dampingFraction: 0.8), value: value)
            Image(systemName: kind.symbol)
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(color)
                .scaleEffect(pulse ? 1.18 : 1)
        }
        .frame(width: size, height: size)
        .onAppear { updatePulse() }
        .onChange(of: value < 25) { _, _ in updatePulse() }
        .accessibilityElement()
        .accessibilityLabel(Text(label))
    }

    private func updatePulse() {
        guard !reduceMotion, kind != .discipline, value < 25 else {
            withAnimation(.easeOut(duration: 0.2)) { pulse = false }
            return
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulse = true }
    }
}

// MARK: - Sheet header

struct SheetHeader: View {
    let title: String
    let onClose: () -> Void
    @Environment(\.palette) private var palette
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack {
            Text(title)
                .font(.rounded(28, .heavy))
                .foregroundStyle(palette.text)
            Spacer()
            IconButton(symbol: "xmark", label: model.t("common.close"), action: onClose)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

/// A segmented control in the app's own style.
struct PillPicker<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value
    @Namespace private var namespace
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.0) { option in
                let selected = option.0 == selection
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = option.0 }
                } label: {
                    Text(option.1)
                        .font(.rounded(15, .bold))
                        .foregroundStyle(selected ? .white : palette.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selected {
                                Capsule().fill(palette.warmGradient)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                            }
                        }
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(palette.surfaceRaised, in: Capsule())
    }
}

// MARK: - Toast

struct ToastView: View {
    let toast: Toast
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.symbol)
                .foregroundStyle(toast.isWarning ? palette.danger : palette.primary)
            Text(toast.text)
                .font(.rounded(15, .semibold))
                .foregroundStyle(palette.text)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(palette.stroke))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Formatting

extension AppModel {
    func duration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let days = total / 86_400
        let hours = (total % 86_400) / 3600
        let minutes = (total % 3600) / 60
        if days > 0 { return t("time.days", days, hours) }
        if hours > 0 { return t("time.hours", hours, minutes) }
        return t("time.minutes", max(1, minutes))
    }
}
