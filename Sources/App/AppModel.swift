import Observation
import SwiftData
import SwiftUI
import WidgetKit

/// A short-lived expression layered over the pet's mood: chewing, laughing…
struct Reaction: Equatable {
    let face: PetPose.Face
    let until: Date
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let symbol: String
    var isWarning = false
}

struct AwaySummary: Identifiable {
    let id = UUID()
    let duration: TimeInterval
    let before: Needs
    let after: Needs
    let lines: [String]
}

/// The single source of truth for the running app: the saved game, the
/// preferences, the transient UI moments and the audio-visual feedback.
@Observable
final class AppModel {

    // MARK: State

    private(set) var save: GameSave
    var preferences: Preferences {
        didSet { preferencesChanged(from: oldValue) }
    }

    var reaction: Reaction?
    var toast: Toast?
    var awaySummary: AwaySummary?
    var evolvedTo: LifeStage?
    /// How many themed layers are stacked (root, sheets, covers); the top
    /// one hosts the toasts.
    var presentationDepth = 0
    /// Where the pet stands inside the effects layer, for particles.
    var petAnchor = CGPoint(x: 200, y: 260)

    @ObservationIgnored let audio = AudioEngine()
    @ObservationIgnored let haptics = Haptics()
    @ObservationIgnored let effects = EffectsScene()
    @ObservationIgnored let notifications = NotificationScheduler()
    @ObservationIgnored let cloud = CloudSync()
    @ObservationIgnored private let store: SharedStore
    @ObservationIgnored private let clock: Clock
    @ObservationIgnored private var context: ModelContext?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var ticksSinceSave = 0

    var pet: PetState { save.pet }
    var household: Household { save.household }
    var stats: LifetimeStats { save.stats }
    var language: AppLanguage { preferences.language }

    init(store: SharedStore = SharedStore(), clock: Clock = SystemClock()) {
        self.store = store
        self.clock = clock
        self.preferences = store.loadPreferences()
        self.save = store.loadSave() ?? GameSave(now: clock.now)
        applyFeedbackPreferences()
        notifications.localize = { [weak self] key in self?.t(key) ?? key }
        cloud.onRemoteChange = { [weak self] remote in self?.adopt(remote) }
        #if DEBUG
        applyQAArguments()
        #endif
    }

    func attach(_ context: ModelContext) {
        self.context = context
    }

    // MARK: Translation

    func t(_ key: String) -> String { Strings.t(key, language) }

    func t(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: t(key), arguments: arguments)
    }

    var colorScheme: ColorScheme? {
        switch preferences.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // MARK: Lifecycle

    func sceneBecameActive() {
        audio.start()
        haptics.start()
        if preferences.iCloudSync {
            cloud.start()
            if let remote = cloud.pull() { adopt(remote) }
        }
        let away = clock.now.timeIntervalSince(save.pet.lastUpdate)
        catchUp(showSummary: away > 10 * 60)
        startTimer()
        notifications.clearDelivered()
    }

    func sceneWentToBackground() {
        timer?.invalidate()
        timer = nil
        persist()
        if preferences.iCloudSync { cloud.push(save) }
        audio.stop()
        haptics.stop()
        rescheduleNotifications()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func startTimer() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: Simulation

    private func engine() -> PetEngine {
        PetEngine(state: save.pet, speed: preferences.speed, clock: clock)
    }

    func tick() {
        var engine = engine()
        let events = engine.update()
        save.pet = engine.state
        handle(events, live: true)
        ticksSinceSave += 1
        if ticksSinceSave >= 10 {
            ticksSinceSave = 0
            persist()
            checkAchievements()
        }
    }

    /// Runs the missed time in one go and, after a real absence, prepares
    /// the "while you were away" card.
    private func catchUp(showSummary: Bool) {
        let before = save.pet
        var engine = engine()
        let events = engine.update()
        save.pet = engine.state
        handle(events, live: false)
        persist()
        // A growth spurt while away still gets its reveal.
        if pet.isAlive, let grown = events.compactMap({ event -> LifeStage? in
            if case .evolved(let stage) = event { return stage }
            return nil
        }).last {
            evolvedTo = grown
        }
        // A farewell tells its own story; no summary on top of it.
        guard showSummary, before.stage != .egg, before.isAlive, pet.isAlive else { return }

        var lines: [String] = []
        let poops = events.filter { $0 == .pooped }.count
        if poops > 0 { lines.append(t("event.pooped", poops)) }
        let tantrums = events.filter { $0 == .tantrumStarted }.count
        if tantrums > 0 { lines.append(t("event.tantrums", tantrums)) }
        if events.contains(.fellAsleep) { lines.append(t("event.slept")) }
        if events.contains(.gotSick) { lines.append(t("event.gotSick", pet.name)) }
        for case .evolved(let stage) in events {
            lines.append(t("event.evolved", pet.name, t("stage.\(stage.rawValue)")))
        }
        awaySummary = AwaySummary(duration: clock.now.timeIntervalSince(before.lastUpdate),
                                  before: before.needs, after: pet.needs, lines: lines)
    }

    private func handle(_ events: [PetEvent], live: Bool) {
        for event in events {
            if event.isMemorable { record(event) }
            guard live else {
                if case .farewell = event { archivePet() }
                continue
            }
            switch event {
            case .evolved(let stage):
                evolvedTo = stage
                effects.play(.evolution, at: petAnchor)
                audio.play(.evolve)
                haptics.play(.evolve)
                WidgetCenter.shared.reloadAllTimelines()
            case .pooped:
                audio.play(.bubble)
            case .wokeUp:
                audio.play(.chirp)
            case .gotSick:
                audio.play(.sad)
                haptics.play(.warning)
            case .tantrumStarted:
                show(Toast(text: t("toast.tantrum", pet.name), symbol: "exclamationmark.bubble.fill", isWarning: true))
                audio.play(.refuse)
            case .lightsMistake:
                show(Toast(text: t("toast.lightsMistake"), symbol: "lightbulb.fill", isWarning: true))
            case .farewell:
                archivePet()
                audio.play(.farewell)
            default:
                break
            }
        }
    }

    // MARK: Memories

    private func record(_ event: PetEvent) {
        let name = pet.name
        let entry: (String, [String], String)?
        switch event {
        case .hatched: entry = ("event.hatched", [name], "sparkles")
        case .evolved(let stage):
            if stage == .adult, let form = pet.form {
                entry = ("event.becameForm", [name, "form.\(form.rawValue)"], form.isRare ? "star.circle.fill" : "arrow.up.circle.fill")
            } else {
                entry = ("event.evolved", [name, "stage.\(stage.rawValue)"], "arrow.up.circle.fill")
            }
        case .gotSick: entry = ("event.gotSick", [name], "thermometer.medium")
        case .recovered: entry = ("event.recovered", [name], "cross.case.fill")
        case .ateTooMuch: entry = ("event.ateTooMuch", [name], "birthday.cake.fill")
        case .farewell: entry = ("event.farewell", [name], "moon.stars.fill")
        default: entry = nil
        }
        guard let entry, let context else { return }
        context.insert(JournalEntry(date: pet.simClock, petID: pet.id, key: entry.0,
                                    arguments: entry.1, symbol: entry.2))
        try? context.save()
    }

    /// Journal arguments that are themselves keys get translated on display.
    func journalText(_ entry: JournalEntry) -> String {
        let args = entry.arguments.map { Strings.all[$0] == nil ? $0 : t($0) }
        return String(format: t(entry.key), arguments: args)
    }

    private func archivePet() {
        guard let context else { return }
        let id = pet.id
        let existing = (try? context.fetch(FetchDescriptor<AlbumEntry>(predicate: #Predicate { $0.petID == id }))) ?? []
        guard existing.isEmpty else { return }
        context.insert(AlbumEntry(pet: pet, endedAt: pet.simClock))
        try? context.save()
        save.stats.longestLife = max(save.stats.longestLife, pet.age)
        persist()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Persistence

    /// Takes over a newer save from another device.
    func adopt(_ remote: GameSave) {
        guard preferences.iCloudSync, save.shouldAdopt(remote) else { return }
        save = remote
        persist()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func persist() {
        store.save(save)
    }

    private func preferencesChanged(from old: Preferences) {
        store.save(preferences)
        applyFeedbackPreferences()
        if old.musicEnabled != preferences.musicEnabled { audio.setMusic(enabled: preferences.musicEnabled) }
        if old.demoMode != preferences.demoMode {
            // Settle the time so far at the old speed before switching.
            var engine = PetEngine(state: save.pet, speed: old.speed, clock: clock)
            _ = engine.update()
            save.pet = engine.state
            persist()
        }
        if old.notificationsEnabled != preferences.notificationsEnabled, preferences.notificationsEnabled {
            notifications.requestAuthorization()
        }
        if old.language != preferences.language || old.demoMode != preferences.demoMode {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func applyFeedbackPreferences() {
        audio.isSoundEnabled = preferences.soundEnabled
        audio.isMusicEnabled = preferences.musicEnabled
        haptics.isEnabled = preferences.hapticsEnabled
    }

    func rescheduleNotifications() {
        guard preferences.notificationsEnabled else {
            notifications.cancelAll()
            return
        }
        let items = Forecast.upcoming(for: pet, speed: preferences.speed, from: clock.now)
        notifications.schedule(items, petName: pet.name)
    }

    // MARK: Toasts and achievements

    func show(_ toast: Toast) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { self.toast = toast }
        let id = toast.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            guard self?.toast?.id == id else { return }
            withAnimation(.easeOut(duration: 0.3)) { self?.toast = nil }
        }
    }

    func checkAchievements() {
        let fresh = save.refreshAchievements(now: clock.now)
        guard let first = fresh.first else { return }
        persist()
        show(Toast(text: t("toast.achievement", t("ach.\(first.rawValue)")), symbol: first.symbol))
        audio.play(.achievement)
        haptics.play(.success)
    }

    // MARK: Mutations used by the care and shop extensions

    func mutate(_ change: (inout GameSave) -> Void) {
        change(&save)
        persist()
    }

    var now: Date { clock.now }

    func makeEngine() -> PetEngine { engine() }

    func recordMemorable(_ event: PetEvent) { record(event) }

    func resetEverything() {
        if let context {
            try? context.delete(model: JournalEntry.self)
            try? context.delete(model: AlbumEntry.self)
            try? context.save()
        }
        store.reset()
        save = GameSave(now: clock.now)
        persist()
        // Overwrite the cloud copy too, or the old pet would come straight back.
        if preferences.iCloudSync { cloud.push(save) }
        notifications.cancelAll()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
