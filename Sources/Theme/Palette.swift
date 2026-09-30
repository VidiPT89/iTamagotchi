import SwiftUI

/// The ividi.dev identity: burnt orange, amber and near-black.
/// Every colour in the app and the widget comes from here.
struct Palette {

    let background: Color
    let surface: Color
    let surfaceRaised: Color
    let stroke: Color
    let primary: Color
    let primaryLight: Color
    let primaryDark: Color
    let accent: Color
    let text: Color
    let textDim: Color
    let textFaint: Color
    let danger: Color
    let success: Color
    let isDark: Bool

    static let dark = Palette(
        background: Color(hex: 0x0A0A0F),
        surface: Color(hex: 0x14131A),
        surfaceRaised: Color(hex: 0x1D1B24),
        stroke: Color.white.opacity(0.08),
        primary: Color(hex: 0xF99C00),
        primaryLight: Color(hex: 0xFCBB00),
        primaryDark: Color(hex: 0xDD7400),
        accent: Color(hex: 0xFCBB00),
        text: Color(hex: 0xF4EFE8),
        textDim: Color(hex: 0xA8A29A),
        textFaint: Color(hex: 0x5F5A55),
        danger: Color(hex: 0xFF5A4E),
        success: Color(hex: 0x3DD68C),
        isDark: true
    )

    static let light = Palette(
        background: Color(hex: 0xFBF6EE),
        surface: Color(hex: 0xFFFFFF),
        surfaceRaised: Color(hex: 0xF3EBDF),
        stroke: Color.black.opacity(0.07),
        primary: Color(hex: 0xDD7400),
        primaryLight: Color(hex: 0xF99C00),
        primaryDark: Color(hex: 0xB65C00),
        accent: Color(hex: 0xE89A00),
        text: Color(hex: 0x17140F),
        textDim: Color(hex: 0x6B6258),
        textFaint: Color(hex: 0xB3A99C),
        danger: Color(hex: 0xD2382B),
        success: Color(hex: 0x1F9D5C),
        isDark: false
    )

    static func resolve(_ scheme: ColorScheme) -> Palette {
        scheme == .dark ? .dark : .light
    }

    var warmGradient: LinearGradient {
        LinearGradient(colors: [primaryLight, primary, primaryDark],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var backdrop: some View {
        ZStack {
            background
            RadialGradient(colors: [primary.opacity(isDark ? 0.20 : 0.14), .clear],
                           center: .top, startRadius: 0, endRadius: 560)
        }
        .ignoresSafeArea()
    }

    /// Colour of a need's ring, from comfortable to urgent.
    func needColor(_ value: Double) -> Color {
        switch value {
        case ..<25: return danger
        case ..<50: return primaryLight
        default: return success
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette.dark
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
