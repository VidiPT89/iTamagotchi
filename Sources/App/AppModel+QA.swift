#if DEBUG
import Foundation
import SwiftData

/// Debug-only launch arguments to open any screen in a known state, e.g.
/// `-qaStage adult -qaForm astro -qaSheet shop -qaSkipSplash YES`.
/// `-qaJournal YES` fills the journal with this life and a past one.
extension AppModel {

    static var qaSkipSplash: Bool { UserDefaults.standard.bool(forKey: "qaSkipSplash") }
    static var qaSheet: String? { UserDefaults.standard.string(forKey: "qaSheet") }

    func applyQAArguments() {
        let args = UserDefaults.standard
        if let lang = args.string(forKey: "qaLang").flatMap(AppLanguage.init(rawValue:)) { preferences.language = lang }
        if let theme = args.string(forKey: "qaTheme").flatMap(AppTheme.init(rawValue:)) { preferences.theme = theme }
        guard let stage = args.string(forKey: "qaStage").flatMap(LifeStage.init(rawValue:)) else { return }

        mutate { save in
            var pet = PetState(now: now)
            pet.name = args.string(forKey: "qaName") ?? "Pipo"
            pet.stage = stage
            if stage >= .adult { pet.form = args.string(forKey: "qaForm").flatMap(AdultForm.init(rawValue:)) ?? .sunny }
            pet.age = 2 * 86_400
            if let mood = args.string(forKey: "qaMood") {
                switch mood {
                case "sick": pet.isSick = true; pet.needs.health = 30
                case "hungry": pet.needs.hunger = 10
                case "dirty": pet.poops = 2; pet.needs.hygiene = 15
                case "angry": pet.isTantrum = true
                case "asleep": pet.isAsleep = true
                case "sad": pet.needs.happiness = 12
                default: break
                }
            }
            save.pet = pet
            save.hasOnboarded = true
            save.household.coins = 480
            save.household.owned.formUnion(["decor.plant", "decor.lamp", "decor.painting", "decor.tree", "hat.crown"])
            save.household.hat = args.string(forKey: "qaHat")
            if args.string(forKey: "qaOverlay") == "farewell" { save.pet.farewell = .oldAge }
        }
        if args.bool(forKey: "qaToast") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self else { return }
                self.show(Toast(text: self.t("toast.bought"), symbol: "bag.fill"))
            }
        }
        switch args.string(forKey: "qaOverlay") {
        case "evolution": evolvedTo = stage
        case "away":
            var before = pet.needs
            before.hunger = 90
            awaySummary = AwaySummary(duration: 5 * 3600, before: before, after: pet.needs,
                                      lines: [t("event.pooped", 2), t("event.slept")])
        default: break
        }
    }

    func seedQAJournal(into context: ModelContext) {
        guard UserDefaults.standard.bool(forKey: "qaJournal") else { return }
        try? context.delete(model: JournalEntry.self)
        try? context.delete(model: AlbumEntry.self)
        var past = PetState(now: now.addingTimeInterval(-9 * 86_400))
        past.name = "Mochi"
        past.stage = .senior
        past.form = .luna
        past.farewell = .oldAge
        past.age = 8 * 86_400
        context.insert(AlbumEntry(pet: past, endedAt: now.addingTimeInterval(-86_400)))
        let lines: [(UUID, String, String, Double, String)] = [
            (past.id, "Mochi", "event.hatched", -9, "sparkles"),
            (past.id, "Mochi", "event.farewell", -1, "moon.stars.fill"),
            (pet.id, pet.name, "event.hatched", -0.5, "sparkles"),
            (pet.id, pet.name, "event.gotSick", -0.2, "thermometer.medium"),
        ]
        for (id, name, key, days, symbol) in lines {
            context.insert(JournalEntry(date: now.addingTimeInterval(days * 86_400), petID: id, key: key,
                                        arguments: [name], symbol: symbol))
        }
        try? context.save()
    }
}
#endif
