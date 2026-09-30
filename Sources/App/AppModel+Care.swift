import SwiftUI
import WidgetKit

/// The player's side of the game: caring, playing, shopping, starting over.
extension AppModel {

    // MARK: Life

    func hatch(named name: String) {
        var engine = makeEngine()
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let events = engine.hatch(named: trimmed.isEmpty ? t("onboarding.namePlaceholder") : String(trimmed.prefix(14)))
        mutate {
            $0.pet = engine.state
            $0.hasOnboarded = true
            $0.stats.petsRaised += 1
        }
        events.filter(\.isMemorable).forEach(record)
        if preferences.iCloudSync { cloud.push(save) }
        audio.play(.hatch)
        haptics.play(.success)
        effects.play(.confetti, at: petAnchor)
        react(.laughing, for: 1.6)
        checkAchievements()
        if preferences.notificationsEnabled { notifications.requestAuthorization() }
    }

    /// Names are trimmed and kept short so they fit the header and widget.
    func rename(to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, pet.stage != .egg else { return }
        mutate { $0.pet.name = String(trimmed.prefix(14)) }
        audio.play(.chirp)
        react(.happy, for: 1)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func startNewEgg() {
        mutate { $0.pet = PetState(now: now, seed: UInt64(now.timeIntervalSince1970)) }
        evolvedTo = nil
        if preferences.iCloudSync { cloud.push(save) }
    }

    // MARK: Care

    func perform(_ action: CareAction) {
        settle()
        var engine = makeEngine()
        let wasSick = engine.state.isSick
        let outcome = engine.perform(action)
        let overfed = action == .snack && engine.isOverfed
        mutate { save in
            save.pet = engine.state
            guard outcome.succeeded else { return }
            switch action {
            case .meal: save.stats.meals += 1
            case .snack: save.stats.snacks += 1
            case .bath: save.stats.baths += 1
            case .clean: save.stats.cleanings += 1
            case .medicine: save.stats.medicines += 1
            case .caress: save.stats.caresses += 1
            default: break
            }
        }

        guard case .done = outcome else {
            if case .refused(let reason) = outcome { refuse(reason) }
            return
        }
        feedback(for: action)

        if overfed {
            show(Toast(text: t("toast.overfed"), symbol: "exclamationmark.triangle.fill", isWarning: true))
            record(.ateTooMuch)
            react(.sick, for: 1.4)
        }
        if action == .medicine, wasSick {
            show(Toast(text: t("toast.cured"), symbol: "cross.case.fill"))
            record(.recovered)
        }
        if action == .scold {
            show(Toast(text: t("toast.disciplined"), symbol: "star.fill"))
        }
        checkAchievements()
    }

    private func feedback(for action: CareAction) {
        let floor = CGPoint(x: petAnchor.x, y: petAnchor.y + 40)
        switch action {
        case .meal, .snack:
            react(.eating, for: 1.8)
            effects.play(.crumbs, at: petAnchor)
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.45) { [weak self] in
                    self?.audio.play(.chomp)
                    self?.haptics.play(.soft)
                }
            }
            if action == .snack {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
                    guard let self else { return }
                    self.effects.play(.hearts, at: self.petAnchor)
                }
            }
        case .clean:
            effects.play(.sparkles, at: floor)
            audio.play(.sweep)
            haptics.play(.tap)
            react(.happy, for: 1)
        case .bath:
            effects.play(.bubbles, at: petAnchor)
            audio.play(.bubble)
            haptics.play(.soft)
            react(.laughing, for: 1.8)
        case .medicine:
            effects.play(.sparkles, at: petAnchor)
            audio.play(.medicine)
            haptics.play(.success)
            react(.refusing, for: 0.8)
        case .toggleLights:
            audio.play(.lights)
            haptics.play(.tap)
        case .scold:
            audio.play(.scold)
            haptics.play(.warning)
            react(.sad, for: 1.2)
        case .caress:
            effects.play(.hearts, at: petAnchor)
            audio.play(.cuddle)
            haptics.play(.heartbeat)
            if !pet.isAsleep { react(.love, for: 1.2) }
        case .played:
            break
        }
    }

    private func refuse(_ reason: Refusal) {
        show(Toast(text: t("refusal.\(reason.rawValue)"), symbol: "hand.raised.fill", isWarning: true))
        audio.play(reason == .unfair ? .sad : .refuse)
        haptics.play(.warning)
        if !pet.isAsleep { react(reason == .unfair || reason == .notSick ? .sad : .refusing, for: 1) }
    }

    func react(_ face: PetPose.Face, for seconds: TimeInterval) {
        reaction = Reaction(face: face, until: Date().addingTimeInterval(seconds))
    }

    // MARK: Games

    var canPlay: Bool { makeEngine().canPlay }

    /// Applies a finished mini-game and returns the coins it paid.
    @discardableResult
    func finishGame(score: Int, won: Bool) -> Int {
        guard isPlayingGame else { return 0 }
        settle()
        var engine = makeEngine()
        let outcome = engine.perform(.played(won: won))
        let coins = outcome.succeeded ? Household.reward(forScore: score, won: won) : 0
        mutate { save in
            save.pet = engine.state
            save.household.coins += coins
            save.stats.coinsEarned += coins
            save.stats.gamesPlayed += 1
            if won { save.stats.gamesWon += 1 }
        }
        audio.play(won ? .win : .lose)
        haptics.play(won ? .success : .soft)
        checkAchievements()
        return coins
    }

    // MARK: Shop

    func buy(_ item: ShopItem) {
        var result = Household.PurchaseResult.unknownItem
        mutate { result = $0.household.buy(item.id) }
        switch result {
        case .bought:
            show(Toast(text: t("toast.bought"), symbol: "bag.fill"))
            audio.play(.coin)
            haptics.play(.success)
            checkAchievements()
        case .notEnoughCoins:
            show(Toast(text: t("toast.notEnough"), symbol: "dollarsign.circle", isWarning: true))
            audio.play(.refuse)
            haptics.play(.warning)
        case .alreadyOwned, .unknownItem:
            break
        }
    }

    func wear(_ hat: String?) {
        mutate { $0.household.hat = hat }
        audio.play(.tap)
        haptics.play(.tap)
        if hat != nil { react(.happy, for: 1) }
        checkAchievements()
    }

    func applyWallpaper(_ id: String) {
        mutate { $0.household.wallpaper = id }
        audio.play(.tap)
        haptics.play(.tap)
    }
}
