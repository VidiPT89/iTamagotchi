import XCTest
@testable import iTamagotchi

/// The app layer on top of the engine: what the player does and what the
/// screen gets told about it.
@MainActor
final class AppModelTests: XCTestCase {

    private let suite = "itamagotchi.tests.model"
    private var defaults: UserDefaults!
    private var clock: ManualClock!
    private var model: AppModel!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        clock = ManualClock(Fixture.date(hour: 12))
        model = AppModel(store: SharedStore(defaults: defaults), clock: clock)
        // Keep the tests away from the real iCloud store and permission prompts.
        model.preferences.iCloudSync = false
        model.preferences.notificationsEnabled = false
        model.hatch(named: "Pipo")
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
    }

    func testHatchingStartsALife() {
        XCTAssertEqual(model.pet.stage, .baby)
        XCTAssertEqual(model.pet.name, "Pipo")
        XCTAssertTrue(model.save.hasOnboarded)
        XCTAssertEqual(model.stats.petsRaised, 1)
    }

    func testAnActionStillShowsAGrowthThatHappenedOnTheWay() {
        clock.advance(by: LifeStage.baby.duration + 30)
        model.perform(.caress)
        XCTAssertEqual(model.pet.stage, .child)
        XCTAssertEqual(model.evolvedTo, .child, "The evolution reveal must not be swallowed by the action")
    }

    func testCareIsCountedOnlyWhenItWorks() {
        model.perform(.clean)
        XCTAssertEqual(model.stats.cleanings, 0, "Nothing to clean yet")
        model.perform(.bath)
        XCTAssertEqual(model.stats.baths, 1)
        XCTAssertEqual(model.pet.needs.hygiene, 100)
    }

    func testAClosedGamePaysNothing() {
        let coins = model.household.coins
        XCTAssertEqual(model.finishGame(score: 40, won: true), 0)
        XCTAssertEqual(model.household.coins, coins)
        XCTAssertEqual(model.stats.gamesPlayed, 0)

        model.isPlayingGame = true
        let paid = model.finishGame(score: 40, won: true)
        XCTAssertEqual(paid, Household.reward(forScore: 40, won: true))
        XCTAssertEqual(model.household.coins, coins + paid)
        XCTAssertEqual(model.stats.gamesWon, 1)
    }

    func testRenameIsTrimmedAndShort() {
        model.rename(to: "   Bolinha de Sabão Gigante  ")
        XCTAssertEqual(model.pet.name, "Bolinha de Sab")
        model.rename(to: "   ")
        XCTAssertEqual(model.pet.name, "Bolinha de Sab", "A blank name is ignored")
    }

    func testShoppingSpendsAndDresses() {
        model.mutate { $0.household.coins = 100 }
        let bow = ShopItem.item("hat.bow")!
        model.buy(bow)
        XCTAssertEqual(model.household.coins, 60)
        XCTAssertEqual(model.household.hat, "hat.bow")
        model.wear(nil)
        XCTAssertNil(model.household.hat)
    }

    func testEverythingIsSavedToTheStore() {
        model.perform(.bath)
        let saved = SharedStore(defaults: defaults).loadSave()
        XCTAssertEqual(saved?.pet.id, model.pet.id)
        XCTAssertEqual(saved?.stats.baths, 1)
    }

    func testANewEggAfterAFarewell() {
        model.mutate { $0.pet.farewell = .oldAge }
        model.startNewEgg()
        XCTAssertEqual(model.pet.stage, .egg)
        XCTAssertTrue(model.pet.isAlive)
        XCTAssertNil(model.evolvedTo)
    }
}
