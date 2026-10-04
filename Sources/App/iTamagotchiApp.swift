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
/// with the colour scheme and the toast layer. Used at the root and on
/// every sheet, which do not always inherit custom environment values.
struct ThemedModifier: ViewModifier {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var systemScheme

    func body(content: Content) -> some View {
        let palette = Palette.resolve(model.colorScheme ?? systemScheme)
        content
            .modifier(ToastHost())
            .environment(\.palette, palette)
            .environment(\.locale, model.language.locale)
            .preferredColorScheme(model.colorScheme)
            .tint(palette.primary)
    }
}

/// Shows the current toast on whichever layer is on top, the home screen or
/// the sheet covering it, so a message is never hidden behind a sheet.
private struct ToastHost: ViewModifier {
    @Environment(AppModel.self) private var model
    @State private var level = 0

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = model.toast, level == model.presentationDepth {
                    ToastView(toast: toast)
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                model.presentationDepth += 1
                level = model.presentationDepth
            }
            .onDisappear { model.presentationDepth -= 1 }
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
