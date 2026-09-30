import XCTest
@testable import iTamagotchi

final class PetEngineTests: XCTestCase {

    func testHatchingStartsBabyLife() {
        let (engine, _) = Fixture.hatchedEngine()
        XCTAssertEqual(engine.state.stage, .baby)
        XCTAssertEqual(engine.state.name, "Pipo")
        XCTAssertEqual(engine.state.needs, Needs())
    }

    func testEggDoesNotDecay() {
        let clock = ManualClock(Fixture.date(hour: 12))
        var engine = PetEngine(state: PetState(now: clock.now), clock: clock)
        clock.advance(by: 5 * 3600)
        XCTAssertTrue(engine.update().isEmpty)
        XCTAssertEqual(engine.state.needs, Needs())
    }

    func testNeedsDecayOverOneHour() {
        var (engine, clock) = Fixture.hatchedEngine()
        let before = engine.state.needs
        clock.advance(by: 3600)
        engine.update()
        XCTAssertEqual(engine.state.needs.hunger, before.hunger - 8, accuracy: 0.01, "Babies get hungry faster")
        XCTAssertEqual(engine.state.needs.happiness, before.happiness - 4.5, accuracy: 0.01)
        XCTAssertEqual(engine.state.needs.energy, before.energy - 3.5, accuracy: 0.01)
        XCTAssertLessThan(engine.state.needs.hygiene, before.hygiene)
    }

    func testOfflineCatchUpRunsTheMissedTime() {
        var (engine, clock) = Fixture.hatchedEngine(hour: 8)
        clock.advance(by: 6 * 3600)
        let events = engine.update()
        XCTAssertEqual(engine.state.age, 6 * 3600, accuracy: 1)
        XCTAssertEqual(engine.state.lastUpdate, clock.now)
        XCTAssertTrue(events.contains(.pooped))
        XCTAssertTrue(events.contains(.evolved(.child)), "A baby grows into a child after an hour")
        XCTAssertGreaterThan(engine.state.poops, 0)
    }

    func testCatchUpIsCappedAtThirtyDays() {
        var (engine, clock) = Fixture.hatchedEngine()
        clock.advance(by: 400 * 24 * 3600)
        engine.update()
        XCTAssertLessThanOrEqual(engine.state.age, PetEngine.maxCatchUp)
    }

    func testDemoModeRunsSixtyTimesFaster() {
        let clock = ManualClock(Fixture.date(hour: 9))
        var engine = PetEngine(state: PetState(now: clock.now), speed: 60, clock: clock)
        _ = engine.hatch(named: "Demo")
        clock.advance(by: 60)
        engine.update()
        XCTAssertEqual(engine.state.age, 3600, accuracy: 1)
        XCTAssertEqual(engine.state.simClock.timeIntervalSince(clock.now), 3600 - 60, accuracy: 1)
    }

    func testFallsAsleepAtNightAndWakesInTheMorning() {
        var (engine, clock) = Fixture.hatchedEngine(hour: 20)
        clock.advance(by: 2 * 3600)
        let evening = engine.update()
        XCTAssertTrue(evening.contains(.fellAsleep))
        XCTAssertTrue(engine.state.isAsleep)
        XCTAssertEqual(engine.perform(.meal), .refused(.asleep))
        XCTAssertEqual(engine.perform(.toggleLights), .done)
        clock.advance(by: 11 * 3600)
        let morning = engine.update()
        XCTAssertTrue(morning.contains(.wokeUp))
        XCTAssertFalse(engine.state.isAsleep)
        XCTAssertTrue(engine.state.lightsOn, "Lights come back on in the morning")
    }

    func testSleepingWithTheLightsOnIsACareMistake() {
        var (engine, clock) = Fixture.hatchedEngine(hour: 20)
        clock.advance(by: 2 * 3600)
        let events = engine.update()
        XCTAssertTrue(events.contains(.lightsMistake))
        XCTAssertEqual(engine.state.upbringing.lightMistakes, 1)
    }

    func testTantrumsAppearAndCanBeDisciplined() {
        var (engine, clock) = Fixture.hatchedEngine(hour: 7)
        engine.state.stage = .child
        engine.state.nextTantrumIn = 30 * 60
        clock.advance(by: 31 * 60)
        XCTAssertTrue(engine.update().contains(.tantrumStarted))
        let discipline = engine.state.needs.discipline
        XCTAssertEqual(engine.perform(.scold), .done)
        XCTAssertFalse(engine.state.isTantrum)
        XCTAssertEqual(engine.state.needs.discipline, discipline + 25, accuracy: 0.01)
    }

    func testIgnoredTantrumCountsAgainstUpbringing() {
        var (engine, clock) = Fixture.hatchedEngine(hour: 7)
        engine.state.stage = .child
        engine.state.isTantrum = true
        clock.advance(by: 25 * 60)
        XCTAssertTrue(engine.update().contains(.tantrumIgnored))
        XCTAssertEqual(engine.state.upbringing.careMistakes, 1)
    }

    func testScoldingWithoutReasonMakesItSad() {
        var (engine, _) = Fixture.hatchedEngine()
        let happiness = engine.state.needs.happiness
        XCTAssertEqual(engine.perform(.scold), .refused(.unfair))
        XCTAssertEqual(engine.state.needs.happiness, happiness - 10, accuracy: 0.01)
    }

    func testMealRefusedWhenFull() {
        var (engine, _) = Fixture.hatchedEngine()
        engine.state.needs.hunger = 97
        XCTAssertEqual(engine.perform(.meal), .refused(.full))
        engine.state.needs.hunger = 40
        XCTAssertEqual(engine.perform(.meal), .done)
        XCTAssertEqual(engine.state.needs.hunger, 70, accuracy: 0.01)
    }

    func testTooManySnacksHurt() {
        var (engine, _) = Fixture.hatchedEngine()
        let health = engine.state.needs.health
        for _ in 0..<4 { _ = engine.perform(.snack) }
        XCTAssertTrue(engine.isOverfed)
        XCTAssertLessThan(engine.state.needs.health, health)
        XCTAssertGreaterThan(engine.state.upbringing.weight, 15)
    }

    func testCleaningAndBath() {
        var (engine, _) = Fixture.hatchedEngine()
        XCTAssertEqual(engine.perform(.clean), .refused(.nothingToClean))
        engine.state.poops = 3
        engine.state.needs.hygiene = 20
        XCTAssertEqual(engine.perform(.clean), .done)
        XCTAssertEqual(engine.state.poops, 0)
        XCTAssertEqual(engine.perform(.bath), .done)
        XCTAssertEqual(engine.state.needs.hygiene, 100)
    }

    func testPlayingNeedsEnergy() {
        var (engine, _) = Fixture.hatchedEngine()
        engine.state.needs.energy = 5
        XCTAssertFalse(engine.canPlay)
        XCTAssertEqual(engine.perform(.played(won: true)), .refused(.tooTired))
        engine.state.needs.energy = 60
        XCTAssertEqual(engine.perform(.played(won: true)), .done)
        XCTAssertEqual(engine.state.needs.energy, 48, accuracy: 0.01)
    }
}

final class WishBubbleTests: XCTestCase {

    func testBubbleShowsTheMostPressingWish() {
        var pet = PetState(now: Date())
        XCTAssertNil(RoomStage.wish(for: pet), "Eggs want nothing")
        pet.stage = .child
        XCTAssertNil(RoomStage.wish(for: pet), "A content pet has no bubble")
        pet.needs.hunger = 10
        XCTAssertEqual(RoomStage.wish(for: pet), "fork.knife")
        pet.isSick = true
        XCTAssertEqual(RoomStage.wish(for: pet), "pills.fill", "Sickness comes before hunger")
        pet.isAsleep = true
        XCTAssertEqual(RoomStage.wish(for: pet), "lightbulb.fill")
        pet.lightsOn = false
        XCTAssertNil(RoomStage.wish(for: pet), "Asleep in the dark: leave it be")
    }

    func testMostUrgentNeedIgnoresDiscipline() {
        var pet = PetState(now: Date())
        pet.needs.discipline = 0
        pet.needs.hygiene = 30
        XCTAssertEqual(pet.mostUrgentNeed, .hygiene)
        pet.needs.hunger = 10
        XCTAssertEqual(pet.mostUrgentNeed, .hunger)
    }
}
