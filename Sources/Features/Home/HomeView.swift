import SwiftData
import SwiftUI

/// The main screen. On iPhone in portrait it stacks needs, room and actions;
/// on iPad and in landscape the room grows and a side panel appears.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    @State private var room: Room = .living
    @State private var feeding = false
    @State private var showStatus = false
    @State private var sheet: HomeSheet?

    enum HomeSheet: String, Identifiable {
        case games, shop, album, stats, settings
        var id: String { rawValue }
    }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 700 || (geo.size.width > geo.size.height && geo.size.width > 560)
            Group {
                if wide {
                    HStack(spacing: 16) {
                        VStack(spacing: 12) {
                            topBar
                            stage
                            ActionBar(feeding: $feeding, onPlay: { sheet = .games })
                        }
                        SidePanel()
                            .frame(width: min(360, geo.size.width * 0.34))
                    }
                } else {
                    VStack(spacing: 12) {
                        topBar
                        NeedsStrip()
                        stage
                        ActionBar(feeding: $feeding, onPlay: { sheet = .games })
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .sheet(item: $sheet) { which in
            Group {
                switch which {
                case .games: GamesHubView()
                case .shop: ShopView()
                case .album: AlbumView()
                case .stats: StatsView()
                case .settings: SettingsView()
                }
            }
            .themed()
            .environment(model)
            .presentationDragIndicator(.visible)
        }
        #if DEBUG
        .onAppear {
            if let raw = AppModel.qaSheet { sheet = HomeSheet(rawValue: raw) }
        }
        #endif
        .sheet(isPresented: $showStatus) {
            StatusCardView()
                .themed()
                .environment(model)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var stage: some View {
        RoomStage(room: $room, feeding: $feeding, showStatus: $showStatus)
            .overlay(alignment: .topLeading) { roomLabel.padding(14) }
            .overlay(alignment: .topTrailing) { sideButtons.padding(12) }
    }

    // MARK: Top bar

    private var topBar: some View {
        let pet = model.pet
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.rounded(28, .heavy))
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 6) {
                    chip(model.t("stage.\(pet.stage.rawValue)"), symbol: "leaf.fill")
                    if let form = pet.form {
                        chip(model.t("form.\(form.rawValue)"), symbol: form.isRare ? "sparkles" : "pawprint.fill")
                    }
                    if model.preferences.demoMode {
                        chip(model.t("home.demo"), symbol: "hare.fill", highlight: true)
                    }
                }
            }
            Spacer(minLength: 8)
            CoinPill(coins: model.household.coins)
            IconButton(symbol: "gearshape.fill", label: model.t("home.settings")) { sheet = .settings }
        }
        .padding(.top, 4)
    }

    private func chip(_ text: String, symbol: String, highlight: Bool = false) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 10, weight: .bold))
            Text(text).font(.rounded(12, .bold))
        }
        .foregroundStyle(highlight ? .white : palette.primary)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(highlight ? AnyShapeStyle(palette.warmGradient) : AnyShapeStyle(palette.primary.opacity(0.14)), in: Capsule())
    }

    private var roomLabel: some View {
        HStack(spacing: 8) {
            Text(model.t("room.\(room.rawValue)"))
                .font(.rounded(13, .bold))
                .foregroundStyle(.white)
                .contentTransition(.opacity)
            HStack(spacing: 4) {
                ForEach(Room.allCases) { r in
                    Capsule()
                        .fill(.white.opacity(r == room ? 1 : 0.45))
                        .frame(width: r == room ? 14 : 6, height: 6)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.black.opacity(0.28), in: Capsule())
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: room)
        .allowsHitTesting(false)
    }

    /// The room is always painted light, so the buttons over it are too,
    /// whatever the app's appearance.
    private var sideButtons: some View {
        VStack(spacing: 10) {
            IconButton(symbol: "bag.fill", label: model.t("home.shop")) { sheet = .shop }
            IconButton(symbol: "book.closed.fill", label: model.t("home.album")) { sheet = .album }
            IconButton(symbol: "trophy.fill", label: model.t("home.stats")) { sheet = .stats }
        }
        .environment(\.palette, .light)
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Needs strip

struct NeedsStrip: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 0) {
            ForEach(NeedKind.allCases) { kind in
                let value = model.pet.needs[kind]
                VStack(spacing: 5) {
                    NeedRing(kind: kind, value: value, size: 42,
                             label: model.t("a11y.need", model.t("need.\(kind.rawValue)"), Int(value)))
                    Text(model.t("need.\(kind.rawValue)"))
                        .font(.rounded(10, .semibold))
                        .foregroundStyle(palette.textDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .card(padding: 12)
    }
}

// MARK: - Action bar

struct ActionBar: View {
    @Binding var feeding: Bool
    let onPlay: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    var body: some View {
        let pet = model.pet
        HStack(spacing: 4) {
            action("fork.knife", "action.feed", badge: pet.needs.hunger < 25, active: feeding) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { feeding.toggle() }
            }
            action("gamecontroller.fill", "action.play", badge: pet.needs.happiness < 25) {
                if model.canPlay { onPlay() } else {
                    model.perform(.played(won: false))
                }
            }
            action("wind", "action.clean", badge: pet.poops > 0) { model.perform(.clean) }
            action("shower.fill", "action.bath", badge: pet.needs.hygiene < 30) { model.perform(.bath) }
            action("pills.fill", "action.medicine", badge: pet.isSick) { model.perform(.medicine) }
            action(pet.lightsOn ? "lightbulb.fill" : "lightbulb.slash.fill",
                   pet.lightsOn ? "action.lightsOff" : "action.lightsOn",
                   badge: pet.isAsleep && pet.lightsOn) { model.perform(.toggleLights) }
            action("hand.raised.fill", "action.scold", badge: pet.isTantrum) { model.perform(.scold) }
        }
        .padding(8)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(palette.stroke))
        .shadow(color: .black.opacity(palette.isDark ? 0.35 : 0.06), radius: 14, y: 6)
    }

    private func action(_ symbol: String, _ key: String, badge: Bool, active: Bool = false,
                        perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(active ? AnyShapeStyle(palette.warmGradient) : AnyShapeStyle(palette.surfaceRaised))
                    Image(systemName: symbol)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(active ? .white : palette.primary)
                        .symbolEffect(.bounce, value: badge)
                }
                .frame(height: 46)
                .overlay(alignment: .topTrailing) {
                    if badge {
                        Circle().fill(palette.danger)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().stroke(palette.surface, lineWidth: 2))
                            .offset(x: 3, y: -3)
                            .transition(.scale)
                    }
                }
                Text(model.t(key))
                    .font(.rounded(10, .semibold))
                    .foregroundStyle(palette.textDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(Text(model.t(key)))
    }
}
