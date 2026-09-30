import XCTest
@testable import iTamagotchi

final class EconomyAndPersistenceTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suite = "itamagotchi.tests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    // MARK: Economy

    func testBuyingSpendsCoins() {
        var home = Household()
        home.coins = 100
        XCTAssertEqual(home.buy("hat.bow"), .bought)
        XCTAssertEqual(home.coins, 60)
        XCTAssertEqual(home.hat, "hat.bow", "A new hat is worn straight away")
        XCTAssertEqual(home.buy("hat.bow"), .alreadyOwned)
        XCTAssertEqual(home.buy("hat.crown"), .notEnoughCoins)
        XCTAssertEqual(home.buy("nope"), .unknownItem)
        XCTAssertEqual(home.coins, 60)
    }

    func testDecorAppearsInItsRoom() {
        var home = Household()
        home.coins = 1_000
        _ = home.buy("decor.plant")
        _ = home.buy("decor.tree")
        XCTAssertEqual(home.decor(in: .living).map(\.id), ["decor.plant"])
        XCTAssertEqual(home.decor(in: .garden).map(\.id), ["decor.tree"])
        XCTAssertTrue(home.decor(in: .bedroom).isEmpty)
    }

    func testGameRewards() {
        XCTAssertEqual(Household.reward(forScore: 0, won: false), 1)
        XCTAssertEqual(Household.reward(forScore: 40, won: true), 30)
    }

    func testCatalogIdsAreUnique() {
        let ids = ShopItem.catalog.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
        XCTAssertTrue(ShopItem.catalog.filter { $0.category == .decor }.allSatisfy { $0.room != nil })
    }

    func testAchievementsUnlockOnce() {
        var save = GameSave(now: Date())
        save.stats.petsRaised = 1
        let first = save.refreshAchievements(now: Date())
        XCTAssertTrue(first.contains(.firstHatch))
        XCTAssertFalse(save.refreshAchievements(now: Date()).contains(.firstHatch))
    }

    // MARK: Persistence

    func testPreferencesRoundTrip() {
        let store = SharedStore(defaults: defaults)
        XCTAssertEqual(store.loadPreferences(), Preferences())
        var prefs = Preferences()
        prefs.language = .en
        prefs.theme = .dark
        prefs.musicEnabled = false
        prefs.demoMode = true
        store.save(prefs)
        XCTAssertEqual(SharedStore(defaults: defaults).loadPreferences(), prefs)
        XCTAssertEqual(prefs.speed, 60)
    }

    func testOlderPreferencesStillDecode() throws {
        let data = Data(#"{"language":"en"}"#.utf8)
        let prefs = try JSONDecoder().decode(Preferences.self, from: data)
        XCTAssertEqual(prefs.language, .en)
        XCTAssertEqual(prefs.theme, .system)
        XCTAssertTrue(prefs.soundEnabled)
    }

    func testGameSaveRoundTrip() {
        let store = SharedStore(defaults: defaults)
        XCTAssertNil(store.loadSave())
        var (engine, clock) = Fixture.hatchedEngine()
        clock.advance(by: 3 * 3600)
        engine.update()
        var save = GameSave(now: clock.now)
        save.pet = engine.state
        save.household.coins = 321
        save.hasOnboarded = true
        store.save(save)
        XCTAssertEqual(store.loadSave(), save)
        store.reset()
        XCTAssertNil(store.loadSave())
    }
}

final class CloudMergeTests: XCTestCase {

    private func save(hatchedAt date: Date, onboarded: Bool = true, stage: LifeStage = .child) -> GameSave {
        var save = GameSave(now: date)
        save.pet.stage = stage
        save.hasOnboarded = onboarded
        return save
    }

    func testNewerSaveWins() {
        let old = save(hatchedAt: Date(timeIntervalSince1970: 1_000))
        let new = save(hatchedAt: Date(timeIntervalSince1970: 2_000))
        XCTAssertTrue(old.shouldAdopt(new))
        XCTAssertFalse(new.shouldAdopt(old))
        XCTAssertFalse(new.shouldAdopt(new), "Nothing to do when identical")
    }

    func testFreshDeviceTakesTheCloudPet() {
        let fresh = save(hatchedAt: Date(timeIntervalSince1970: 5_000), onboarded: false, stage: .egg)
        let cloud = save(hatchedAt: Date(timeIntervalSince1970: 1_000))
        XCTAssertTrue(fresh.shouldAdopt(cloud))
    }

    func testAnEggNeverReplacesALivingPet() {
        let pet = save(hatchedAt: Date(timeIntervalSince1970: 1_000))
        let egg = save(hatchedAt: Date(timeIntervalSince1970: 9_000), stage: .egg)
        XCTAssertFalse(pet.shouldAdopt(egg))
        XCTAssertTrue(egg.shouldAdopt(pet))
    }

    func testAFarewellNeverReplacesANewEgg() {
        var gone = save(hatchedAt: Date(timeIntervalSince1970: 9_000))
        gone.pet.farewell = .oldAge
        let egg = save(hatchedAt: Date(timeIntervalSince1970: 1_000), stage: .egg)
        XCTAssertFalse(egg.shouldAdopt(gone), "The player already moved on to a new egg")
    }

    func testResetSaveIsNeverAdopted() {
        let pet = save(hatchedAt: Date(timeIntervalSince1970: 1_000))
        let reset = save(hatchedAt: Date(timeIntervalSince1970: 9_000), onboarded: false, stage: .egg)
        XCTAssertFalse(pet.shouldAdopt(reset))
    }

    func testPreferencesDefaultToSync() throws {
        let prefs = try JSONDecoder().decode(Preferences.self, from: Data("{}".utf8))
        XCTAssertTrue(prefs.iCloudSync)
    }
}
