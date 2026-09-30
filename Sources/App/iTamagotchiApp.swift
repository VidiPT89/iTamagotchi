import SwiftData
import SwiftUI

@main
struct iTamagotchiApp: App {
    @State private var model = AppModel()
    private let container = MemoryStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .themed()
                .environment(model)
                .modelContainer(container)
        }
    }
}

/// Resolves the palette from the chosen appearance and applies it, along
/// with the colour scheme. Used at the root and on every sheet, which do not
/// always inherit custom environment values.
struct ThemedModifier: ViewModifier {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var systemScheme

    func body(content: Content) -> some View {
        let palette = Palette.resolve(model.colorScheme ?? systemScheme)
        content
            .environment(\.palette, palette)
            .preferredColorScheme(model.colorScheme)
            .tint(palette.primary)
    }
}

extension View {
    func themed() -> some View { modifier(ThemedModifier()) }
}

enum Links {
    static let website = URL(string: "https://ividi.dev/")!
    static let github = URL(string: "https://github.com/VidiPT89/")!
}

enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
}
