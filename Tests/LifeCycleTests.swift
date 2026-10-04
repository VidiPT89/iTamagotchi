import XCTest
@testable import iTamagotchi

final class LifeCycleTests: XCTestCase {

    // MARK: Sickness

    func testNeglectMakesThePetSick() {
        var (engine, clock) = Fixture.hatchedEngine()
        engine.state.needs.hunger = 0
        engine.state.needs.hygiene = 0
        engine.state.poops = 4
        clock.advance(by: 8 * 3600)
        XCTAssertTrue(engine.update().contains(.gotSick))
        XCTAssertTrue(engine.state.isSick)
        XCTAssertEqual(engine.state.mood == .sick || engine.state.isAsleep, true)
    }

    func testMedicineCuresOnlyWhenSick() {
        var (engine, _) = Fixture.hatchedEngine()
        XCTAssertEqual(engine.perform(.medicine), .refused(.notSick))
        engine.state.isSick = true
        engine.state.needs.health = 20
        XCTAssertEqual(engine.perform(.medicine), .done)
        XCTAssertFalse(engine.state.isSick)
        XCTAssertGreaterThanOrEqual(engine.state.needs.health, 70)
    }

    func testEmptyNeedCountsAsCareMistakeOnce() {
        var (engine, clock) = Fixture.hatchedEngine()
        engine.state.needs.happiness = 0
        clock.advance(by: 2 * 3600)
        let events = engine.update()
        XCTAssertEqual(events.filter { $0 == .careMistake }.count, 1)
    }

    // MARK: Farewell

    func testLongNeglectEndsInFarewell() {
        var (engine, clock) = Fixture.hatchedEngine()
        engine.state.needs = Needs(hunger: 0, happiness: 0, energy: 50, hygiene: 0, health: 0, discipline: 0)
        clock.advance(by: 7 * 3600)
        let events = engine.update()
        XCTAssertTrue(events.contains(.farewell(.neglect)))
        XCTAssertFalse(engine.state.isAlive)
        XCTAssertEqual(engine.perform(.meal), .refused(.notHatched))
    }

    func testSeniorsEventuallyReturnToTheirPlanet() {
        var (engine, _) = Fixture.hatchedEngine()
        engine.state.stage = .senior
        engine.state.stageAge = LifeStage.senior.duration - 60
        var events: [PetEvent] = []
        for _ in 0..<3 {
            // Keep it healthy so only old age can end it.
            engine.state.needs = Needs(hunger: 100, happiness: 100, energy: 100, hygiene: 100, health: 100, discipline: 100)
            events += engine.simulate(seconds: 60)
        }
        XCTAssertTrue(events.contains(.farewell(.oldAge)))
    }

    // MARK: Growth

    func testStagesFollowTheirDurations() {
        var (engine, _) = Fixture.hatchedEngine()
        var stages: [LifeStage] = []
        for stage in [LifeStage.baby, .child, .teen, .adult] {
            engine.state.needs = Needs(hunger: 100, happiness: 100, energy: 100, hygiene: 100, health: 100, discipline: 100)
            engine.state.stageAge = stage.duration - 30
            for case .evolved(let next) in engine.simulate(seconds: 60) { stages.append(next) }
        }
        XCTAssertEqual(stages, [.child, .teen, .adult, .senior])
        XCTAssertNotNil(engine.state.form, "Adults are given a form")
    }

    func testAdultFormBranches() {
        func form(_ mistakes: Int, _ lights: Int, _ happy: Double, _ disc: Double, _ weight: Double) -> AdultForm {
            Upbringing(careMistakes: mistakes, lightMistakes: lights, happinessAverage: happy,
                       disciplineAverage: disc, weight: weight).adultForm()
        }
        XCTAssertEqual(form(0, 0, 90, 90, 10), .astro)
        XCTAssertEqual(form(2, 0, 50, 65, 10), .luna)
        XCTAssertEqual(form(2, 1, 50, 65, 35), .pudding)
        XCTAssertEqual(form(3, 1, 70, 40, 10), .sunny)
        XCTAssertEqual(form(5, 2, 50, 60, 10), .nimbus)
        XCTAssertEqual(form(5, 2, 50, 30, 10), .ember)
        XCTAssertEqual(form(9, 3, 50, 30, 10), .pebble)
        XCTAssertEqual(form(9, 3, 20, 30, 10), .grumble)
        XCTAssertEqual(AdultForm.allCases.count, 8)
        XCTAssertEqual(AdultForm.allCases.filter(\.isRare), [.astro, .luna])
    }

    func testUpbringingAveragesAreSampledWhileGrowing() {
        var (engine, _) = Fixture.hatchedEngine(hour: 8)
        engine.state.stage = .child
        engine.state.needs.discipline = 90
        engine.state.needs.happiness = 90
        _ = engine.simulate(seconds: 600)
        XCTAssertGreaterThan(engine.state.upbringing.disciplineAverage, 80)
        XCTAssertGreaterThan(engine.state.upbringing.happinessAverage, 80)
    }

    // MARK: Forecast

    func testForecastPredictsHunger() {
        let (engine, clock) = Fixture.hatchedEngine(hour: 9)
        let items = Forecast.upcoming(for: engine.state, speed: 1, from: clock.now)
        let hungry = items.first { $0.alert == .hungry }
        XCTAssertNotNil(hungry)
        XCTAssertGreaterThan(hungry!.date, clock.now)
        XCTAssertLessThan(hungry!.date, clock.now.addingTimeInterval(24 * 3600))
    }

    func testForecastIsEmptyForEggs() {
        let state = PetState(now: Date())
        XCTAssertTrue(Forecast.upcoming(for: state, speed: 1, from: Date()).isEmpty)
    }
    func testNeglectAtGrowthBoundaryDoesNotEvolveAfterFarewell() {
        var (engine, _) = Fixture.hatchedEngine()
        engine.state.stage = .teen
        engine.state.stageAge = LifeStage.teen.duration - 60
        engine.state.needs.hunger = 0
        engine.state.needs.health = 0
        engine.state.healthEmptyFor = 6 * 3600 - 60
        let events = engine.simulate(seconds: 60)
        XCTAssertEqual(events.filter { if case .farewell = $0 { return true }; return false }.count, 1)
        XCTAssertFalse(events.contains(.evolved(.adult)))
        XCTAssertEqual(engine.state.stage, .teen)
    }

    func testOfflineFarewellKeepsActualEndTime() {
        var (engine, clock) = Fixture.hatchedEngine()
        engine.state.stage = .senior
        engine.state.stageAge = LifeStage.senior.duration - 60
        let end = engine.state.simClock.addingTimeInterval(60)
        clock.advance(by: 3600)
        engine.update()
        XCTAssertEqual(engine.state.simClock, end)
        clock.advance(by: 3600)
        engine.update()
        XCTAssertEqual(engine.state.simClock, end)
    }

    func testGrowthPreservesPartialStep() {
        var (engine, _) = Fixture.hatchedEngine()
        engine.state.stageAge = LifeStage.baby.duration - 30
        _ = engine.simulate(seconds: 60)
        XCTAssertEqual(engine.state.stage, .child)
        XCTAssertEqual(engine.state.stageAge, 30)
    }

}
