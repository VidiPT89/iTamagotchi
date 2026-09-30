import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var notificationsDenied = false
    @State private var versionTaps = 0
    @State private var page: Page?

    enum Page: Hashable { case howTo, about }

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ZStack {
                palette.backdrop
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SheetHeader(title: model.t("settings.title")) { dismiss() }
                            .padding(.horizontal, -20)

                        section("settings.language", symbol: "globe") {
                            PillPicker(options: AppLanguage.allCases.map { ($0, "\($0.flag)  \($0.label)") },
                                       selection: $model.preferences.language)
                        }

                        section("settings.appearance", symbol: "circle.lefthalf.filled") {
                            PillPicker(options: AppTheme.allCases.map { ($0, model.t("settings.theme.\($0.rawValue)")) },
                                       selection: $model.preferences.theme)
                        }

                        section("settings.audio", symbol: "speaker.wave.2.fill") {
                            VStack(spacing: 4) {
                                toggle("settings.sound", isOn: $model.preferences.soundEnabled)
                                Divider()
                                toggle("settings.music", isOn: $model.preferences.musicEnabled)
                                Divider()
                                toggle("settings.haptics", isOn: $model.preferences.hapticsEnabled)
                            }
                        }

                        section("settings.notifications", symbol: "bell.badge.fill") {
                            VStack(alignment: .leading, spacing: 6) {
                                toggle("settings.notifications", isOn: $model.preferences.notificationsEnabled)
                                Text(model.t(notificationsDenied ? "settings.notificationsDenied" : "settings.notificationsHint"))
                                    .font(.rounded(12, .medium))
                                    .foregroundStyle(notificationsDenied ? palette.danger : palette.textDim)
                            }
                        }

                        section("settings.gameplay", symbol: "gamecontroller.fill") {
                            VStack(alignment: .leading, spacing: 10) {
                                if versionTaps >= 5 || model.preferences.demoMode {
                                    toggle("settings.demo", isOn: $model.preferences.demoMode)
                                    Text(model.t("settings.demoHint"))
                                        .font(.rounded(12, .medium))
                                        .foregroundStyle(palette.textDim)
                                    Divider()
                                }
                                toggle("settings.icloud", isOn: $model.preferences.iCloudSync)
                                Text(model.t("settings.icloudHint"))
                                    .font(.rounded(12, .medium))
                                    .foregroundStyle(palette.textDim)
                                Divider()
                                Button(role: .destructive) { confirmReset = true } label: {
                                    Label(model.t("settings.reset"), systemImage: "arrow.counterclockwise")
                                        .font(.rounded(16, .semibold))
                                        .foregroundStyle(palette.danger)
                                }
                                .buttonStyle(.pressable)
                            }
                        }

                        section("settings.info", symbol: "info.circle.fill") {
                            VStack(spacing: 4) {
                                link("settings.howToPlay", symbol: "questionmark.circle.fill") { page = .howTo }
                                Divider()
                                link("settings.about", symbol: "person.crop.circle.fill") { page = .about }
                            }
                        }

                        Button {
                            versionTaps += 1
                            if versionTaps == 5 { model.haptics.play(.success); model.audio.play(.achievement) }
                        } label: {
                            Text(model.t("about.version", AppInfo.version))
                                .font(.rounded(12, .medium))
                                .foregroundStyle(palette.textFaint)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHidden(true)
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $page) { page in
                Group {
                    switch page {
                    case .howTo: HowToPlayView()
                    case .about: AboutView()
                    }
                }
                .toolbar(.visible, for: .navigationBar)
            }
        }
        .alert(model.t("settings.resetTitle"), isPresented: $confirmReset) {
            Button(model.t("common.cancel"), role: .cancel) {}
            Button(model.t("settings.reset"), role: .destructive) {
                model.resetEverything()
                dismiss()
            }
        } message: {
            Text(model.t("settings.resetMessage"))
        }
        .onAppear(perform: refreshNotificationStatus)
        .onChange(of: model.preferences.notificationsEnabled) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: refreshNotificationStatus)
        }
    }

    private func refreshNotificationStatus() {
        model.notifications.authorizationDenied { notificationsDenied = $0 }
    }

    private func section<Content: View>(_ key: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(model.t(key), systemImage: symbol)
                .font(.rounded(13, .bold))
                .textCase(.uppercase)
                .foregroundStyle(palette.textDim)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .card(padding: 14)
        }
    }

    private func toggle(_ key: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(model.t(key)).font(.rounded(16, .semibold)).foregroundStyle(palette.text)
        }
        .tint(palette.primary)
        .padding(.vertical, 4)
    }

    private func link(_ key: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: symbol).foregroundStyle(palette.primary).frame(width: 24)
                Text(model.t(key)).font(.rounded(16, .semibold)).foregroundStyle(palette.text)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(palette.textFaint)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }
}

// MARK: - About

struct AboutView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            palette.backdrop
            ScrollView {
                VStack(spacing: 18) {
                    Canvas { ctx, size in
                        PetRenderer.drawEgg(&ctx, in: size, wobble: .degrees(-4), cracks: 1, glow: 0.7)
                    }
                    .frame(width: 110, height: 140)
                    .accessibilityHidden(true)
                    HStack(spacing: 0) {
                        Text("i").foregroundStyle(palette.text)
                        Text("Tamagotchi").foregroundStyle(palette.warmGradient)
                    }
                    .font(.rounded(38, .heavy))
                    Text(model.t("about.version", AppInfo.version))
                        .font(.rounded(13, .medium))
                        .foregroundStyle(palette.textDim)
                    Text(model.t("about.body"))
                        .font(.rounded(16, .medium))
                        .foregroundStyle(palette.text)
                        .multilineTextAlignment(.center)
                        .card()
                    VStack(spacing: 12) {
                        Text(model.t("about.developedBy"))
                            .font(.rounded(16, .bold))
                            .foregroundStyle(palette.text)
                        linkRow(model.t("about.website"), detail: "ividi.dev", symbol: "globe", url: Links.website,
                                label: model.t("a11y.openWebsite"))
                        linkRow(model.t("about.github"), detail: "github.com/VidiPT89", symbol: "chevron.left.forwardslash.chevron.right",
                                url: Links.github, label: model.t("a11y.openGitHub"))
                    }
                    .card()
                }
                .padding(20)
            }
        }
        .navigationTitle(model.t("settings.about"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func linkRow(_ title: String, detail: String, symbol: String, url: URL, label: String) -> some View {
        Button { openURL(url) } label: {
            HStack {
                Image(systemName: symbol).foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(palette.warmGradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.rounded(15, .bold)).foregroundStyle(palette.text)
                    Text(detail).font(.rounded(13, .medium)).foregroundStyle(palette.primary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(palette.textFaint)
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(Text(label))
    }
}

// MARK: - How to play

struct HowToPlayView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    private let topics: [(String, String)] = [
        ("life", "arrow.triangle.2.circlepath"), ("needs", "heart.circle.fill"), ("care", "hands.sparkles.fill"),
        ("discipline", "hand.raised.fill"), ("evolution", "sparkles"), ("coins", "bag.fill"), ("gestures", "hand.tap.fill"),
    ]

    var body: some View {
        ZStack {
            palette.backdrop
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(topics, id: \.0) { topic in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: topic.1)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(palette.warmGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(model.t("howto.\(topic.0).title")).font(.rounded(17, .bold)).foregroundStyle(palette.text)
                                Text(model.t("howto.\(topic.0).body")).font(.rounded(14, .medium)).foregroundStyle(palette.textDim)
                            }
                            Spacer(minLength: 0)
                        }
                        .card(padding: 14)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(model.t("howto.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
