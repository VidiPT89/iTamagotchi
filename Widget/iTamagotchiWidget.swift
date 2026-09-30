import SwiftUI
import WidgetKit

@main
struct iTamagotchiWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetWidget()
    }
}

struct PetEntry: TimelineEntry {
    let date: Date
    let pet: PetState?
    let hat: String?
    let language: AppLanguage
}

/// Reads the save from the App Group and projects it forward with the same
/// engine the app uses, so the needs keep draining on the Home Screen too.
struct PetProvider: TimelineProvider {
    private let store = SharedStore()

    func placeholder(in context: Context) -> PetEntry {
        var pet = PetState(now: Date())
        pet.stage = .child
        pet.name = "Pipo"
        return PetEntry(date: Date(), pet: pet, hat: nil, language: .pt)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
        completion(entries(count: 1).first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
        let list = entries(count: 8)
        let refresh = list.last?.date ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: list, policy: .after(refresh)))
    }

    private func entries(count: Int) -> [PetEntry] {
        let prefs = store.loadPreferences()
        guard let save = store.loadSave() else {
            return [PetEntry(date: Date(), pet: nil, hat: nil, language: prefs.language)]
        }
        let step: TimeInterval = prefs.demoMode ? 60 : 30 * 60
        let start = Date()
        var pet = save.pet
        var result: [PetEntry] = []
        // Each entry picks up where the previous one stopped, so a long
        // absence is caught up once rather than once per entry.
        for i in 0..<count {
            let date = start.addingTimeInterval(Double(i) * step)
            var engine = PetEngine(state: pet, speed: prefs.speed, clock: FixedClock(now: date))
            _ = engine.update()
            pet = engine.state
            result.append(PetEntry(date: date, pet: pet, hat: save.household.hat, language: prefs.language))
        }
        return result
    }
}

private struct FixedClock: Clock {
    let now: Date
}

struct PetWidget: Widget {
    var body: some WidgetConfiguration {
        let language = SharedStore().loadPreferences().language
        return StaticConfiguration(kind: "PetWidget", provider: PetProvider()) { entry in
            PetWidgetView(entry: entry)
        }
        .configurationDisplayName(Strings.t("widget.name", language))
        .description(Strings.t("widget.description", language))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct PetWidgetView: View {
    let entry: PetEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme

    private var palette: Palette { .resolve(scheme) }

    var body: some View {
        Group {
            if let pet = entry.pet, pet.stage != .egg, pet.isAlive {
                switch family {
                case .systemMedium: medium(pet)
                case .accessoryCircular: circular(pet)
                case .accessoryRectangular: rectangular(pet)
                case .accessoryInline: inline(pet)
                default: small(pet)
                }
            } else if family == .accessoryCircular {
                Image(systemName: "oval.portrait.fill").font(.title2)
            } else if family == .accessoryRectangular || family == .accessoryInline {
                Text(emptyText)
            } else {
                empty
            }
        }
        .environment(\.locale, entry.language.locale)
        .containerBackground(for: .widget) {
            ZStack {
                palette.background
                RadialGradient(colors: [palette.primary.opacity(0.28), .clear], center: .top, startRadius: 0, endRadius: 200)
            }
        }
    }

    private func t(_ key: String) -> String { Strings.t(key, entry.language) }

    private func petCanvas(_ pet: PetState) -> some View {
        Canvas { ctx, size in
            PetRenderer.draw(&ctx, in: size, look: PetAppearance.of(stage: pet.stage, form: pet.form),
                             pose: .still(for: pet.mood), hat: entry.hat)
        }
    }

    private func small(_ pet: PetState) -> some View {
        VStack(spacing: 4) {
            petCanvas(pet)
            HStack(spacing: 4) {
                Text(pet.name).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(palette.text)
                    .lineLimit(1)
                if pet.needsAttention {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(palette.danger).font(.system(size: 12))
                }
            }
            HStack(spacing: 5) {
                ForEach([NeedKind.hunger, .happiness, .energy, .hygiene], id: \.self) { kind in
                    miniBar(pet.needs[kind])
                }
            }
        }
    }

    private func medium(_ pet: PetState) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                petCanvas(pet)
                Text(pet.name).font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(palette.text)
                Text(t("mood.\(pet.mood.rawValue)")).font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primary)
            }
            .frame(maxWidth: 130)
            VStack(spacing: 7) {
                ForEach([NeedKind.hunger, .happiness, .energy, .hygiene, .health], id: \.self) { kind in
                    HStack(spacing: 6) {
                        Image(systemName: kind.symbol)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(palette.needColor(pet.needs[kind]))
                            .frame(width: 14)
                        Text(t("need.\(kind.rawValue)"))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.textDim)
                            .frame(width: 66, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        miniBar(pet.needs[kind])
                    }
                }
            }
        }
    }

    private func miniBar(_ value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.text.opacity(0.1))
                Capsule().fill(palette.needColor(value)).frame(width: max(4, geo.size.width * value / 100))
            }
        }
        .frame(height: 6)
    }

    // MARK: Lock Screen

    /// The most urgent need as a ring around its symbol.
    private func circular(_ pet: PetState) -> some View {
        let kind = pet.mostUrgentNeed
        return Gauge(value: pet.needs[kind], in: 0...100) {
            Image(systemName: kind.symbol)
        } currentValueLabel: {
            Image(systemName: kind.symbol)
        }
        .gaugeStyle(.accessoryCircular)
        .widgetAccentable()
        .accessibilityLabel(Text(String(format: t("a11y.need"), t("need.\(kind.rawValue)"), Int(pet.needs[kind]))))
    }

    /// Name, mood and the need that wants attention first.
    private func rectangular(_ pet: PetState) -> some View {
        let kind = pet.mostUrgentNeed
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(pet.name).font(.headline).lineLimit(1)
                if pet.needsAttention { Image(systemName: "exclamationmark.circle.fill") }
            }
            .widgetAccentable()
            Text(t("mood.\(pet.mood.rawValue)")).font(.caption).lineLimit(1)
            Gauge(value: pet.needs[kind], in: 0...100) {
                Label(t("need.\(kind.rawValue)"), systemImage: kind.symbol)
            }
            .gaugeStyle(.accessoryLinearCapacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inline(_ pet: PetState) -> some View {
        Label("\(pet.name) · \(t("mood.\(pet.mood.rawValue)"))",
              systemImage: pet.needsAttention ? "exclamationmark.circle.fill" : "pawprint.fill")
    }

    private var emptyText: String {
        t(entry.pet?.isAlive == false ? "widget.gone" : "widget.noPet")
    }

    private var empty: some View {
        VStack(spacing: 6) {
            Canvas { ctx, size in
                PetRenderer.drawEgg(&ctx, in: size, wobble: .degrees(-5), cracks: 1, glow: 0.5)
            }
            Text(emptyText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.textDim)
                .multilineTextAlignment(.center)
        }
    }
}
