import Foundation

// MARK: - Clock

/// Where "now" comes from. The app uses the system clock, the tests move a
/// manual one forward so every scenario is exact and instant.
protocol Clock {
    var now: Date { get }
}

struct SystemClock: Clock {
    var now: Date { Date() }
}

// MARK: - Actions

enum CareAction: Equatable {
    case meal, snack, clean, bath, medicine, toggleLights, scold, caress
    case played(won: Bool)
}

enum ActionOutcome: Equatable {
    case done
    case refused(Refusal)

    var succeeded: Bool { self == .done }
}

enum Refusal: String, Equatable {
    case asleep, full, nothingToClean, notSick, unfair, tooTired, notHatched
}

// MARK: - Engine

/// The whole simulation, with no UI in sight. It advances the pet through
/// time in small fixed steps and applies the player's care.
struct PetEngine {

    var state: PetState
    /// Simulated seconds per real second. 1 in normal play, 60 in demo mode.
    var speed: Double
    private let clock: Clock

    /// Size of one simulation step. Small enough that thresholds are hit on
    /// time, big enough that a week away is caught up in a blink.
    static let step: TimeInterval = 60
    /// Nobody can come back to more than this much missed time.
    static let maxCatchUp: TimeInterval = 30 * 24 * 3600

    init(state: PetState, speed: Double = 1, clock: Clock = SystemClock()) {
        self.state = state
        self.speed = speed
        self.clock = clock
    }

    // MARK: Time

    /// Brings the pet up to the clock's current time.
    @discardableResult
    mutating func update() -> [PetEvent] {
        let now = clock.now
        let realElapsed = max(0, now.timeIntervalSince(state.lastUpdate))
        state.lastUpdate = now
        guard state.stage != .egg, state.isAlive else {
            state.simClock = speed == 1 ? now : state.simClock
            return []
        }

        var remaining = min(realElapsed * speed, Self.maxCatchUp)
        var events: [PetEvent] = []
        while remaining > 0, state.isAlive {
            let dt = min(Self.step, remaining)
            events += advance(by: dt)
            remaining -= dt
        }
        // At normal speed the simulated clock is simply the real one.
        if speed == 1 { state.simClock = now }
        return events
    }

    /// Runs `seconds` of simulated time. Public so forecasts can look ahead.
    mutating func simulate(seconds: TimeInterval) -> [PetEvent] {
        var remaining = seconds
        var events: [PetEvent] = []
        while remaining > 0, state.isAlive, state.stage != .egg {
            let dt = min(Self.step, remaining)
            events += advance(by: dt)
            remaining -= dt
        }
        return events
    }

    private mutating func advance(by dt: TimeInterval) -> [PetEvent] {
        var events: [PetEvent] = []
        let hours = dt / 3600
        state.simClock = state.simClock.addingTimeInterval(dt)
        state.age += dt
        state.stageAge += dt

        decayNeeds(hours: hours)
        events += updateSleep(dt: dt)
        events += updatePoop(dt: dt)
        events += updateHealth(dt: dt, hours: hours)
        events += updateTantrum(dt: dt)
        events += checkNeglect(dt: dt)
        sampleUpbringing(dt: dt)
        events += checkGrowth()
        return events
    }

    // MARK: Needs

    private mutating func decayNeeds(hours: Double) {
        let asleep = state.isAsleep
        let slow = asleep ? 0.4 : 1.0
        let hungerRate = state.stage == .baby ? 8.0 : 5.5
        state.needs[.hunger] -= hungerRate * hours * slow
        state.needs[.happiness] -= 4.5 * hours * slow
        state.needs[.hygiene] -= (2.5 + 3 * Double(state.poops)) * hours * (asleep ? 0.5 : 1)
        state.needs[.discipline] -= 0.5 * hours
        state.recentSnacks = max(0, state.recentSnacks - hours)

        if asleep {
            // A bright room makes for poor sleep.
            state.needs[.energy] += (state.lightsOn ? 5 : 14) * hours
        } else {
            state.needs[.energy] -= 3.5 * hours
        }
    }

    private mutating func updateSleep(dt: TimeInterval) -> [PetEvent] {
        let night = Self.isNight(state.simClock)
        if !state.isAsleep {
            guard night || state.needs.energy < 8 else { return [] }
            state.isAsleep = true
            state.isTantrum = false
            state.lightMistakeCounted = false
            state.lightsOnWhileAsleepFor = 0
            return [.fellAsleep]
        }

        if !night, state.needs.energy >= 90 {
            state.isAsleep = false
            state.lightsOn = true
            return [.wokeUp]
        }

        guard state.lightsOn else {
            state.lightsOnWhileAsleepFor = 0
            return []
        }
        state.lightsOnWhileAsleepFor += dt
        if state.lightsOnWhileAsleepFor >= 30 * 60, !state.lightMistakeCounted {
            state.lightMistakeCounted = true
            state.upbringing.lightMistakes += 1
            state.upbringing.careMistakes += 1
            return [.lightsMistake]
        }
        return []
    }

    private mutating func updatePoop(dt: TimeInterval) -> [PetEvent] {
        guard !state.isAsleep else { return [] }
        state.poopTimer += dt
        let interval: TimeInterval = state.stage == .baby ? 2 * 3600 : 3 * 3600
        guard state.poopTimer >= interval else { return [] }
        state.poopTimer = 0
        guard state.poops < 4 else { return [] }
        state.poops += 1
        return [.pooped]
    }

    private mutating func updateHealth(dt: TimeInterval, hours: Double) -> [PetEvent] {
        var delta = 0.0
        if state.needs.hunger < 15 { delta -= 5 }
        if state.needs.hygiene < 20 { delta -= 3 }
        delta -= 1.5 * Double(state.poops)
        if state.isSick {
            delta -= 2
        } else if state.needs.average > 45, state.poops == 0 {
            delta += 2
        }
        if state.stage == .senior { delta -= 0.5 }
        state.needs[.health] += delta * hours

        if !state.isSick, state.needs.health < 35 {
            state.isSick = true
            return [.gotSick]
        }
        return []
    }

    private mutating func updateTantrum(dt: TimeInterval) -> [PetEvent] {
        guard state.stage >= .child, !state.isAsleep, !state.isSick else { return [] }
        if state.isTantrum {
            state.tantrumAge += dt
            guard state.tantrumAge >= 20 * 60 else { return [] }
            state.isTantrum = false
            state.upbringing.careMistakes += 1
            state.needs[.discipline] -= 10
            return [.tantrumIgnored]
        }
        state.tantrumTimer += dt
        guard state.tantrumTimer >= state.nextTantrumIn else { return [] }
        state.tantrumTimer = 0
        state.nextTantrumIn = TimeInterval.random(in: 3 * 3600...6 * 3600, using: &state.rng)
        state.isTantrum = true
        state.tantrumAge = 0
        return [.tantrumStarted]
    }

    /// A need left empty for twenty minutes counts against the upbringing,
    /// once per time it runs out.
    private mutating func checkNeglect(dt: TimeInterval) -> [PetEvent] {
        var events: [PetEvent] = []
        if tick(&state.hungerEmptyFor, empty: state.needs.hunger <= 0, dt: dt) {
            events.append(.careMistake)
        }
        if tick(&state.happinessEmptyFor, empty: state.needs.happiness <= 0, dt: dt) {
            events.append(.careMistake)
        }
        if !events.isEmpty { state.upbringing.careMistakes += events.count }

        if state.needs.health <= 0 {
            state.healthEmptyFor += dt
            if state.healthEmptyFor >= 6 * 3600 { events.append(say(goodbye: .neglect)) }
        } else {
            state.healthEmptyFor = 0
        }
        return events
    }

    /// Advances an "empty" timer and reports the moment it crosses the limit.
    private func tick(_ timer: inout TimeInterval, empty: Bool, dt: TimeInterval) -> Bool {
        guard empty else { timer = 0; return false }
        let before = timer
        timer += dt
        return before < 20 * 60 && timer >= 20 * 60
    }

    private mutating func sampleUpbringing(dt: TimeInterval) {
        guard state.stage == .child || state.stage == .teen else { return }
        let total = state.averagedTime + dt
        let weight = dt / total
        state.upbringing.happinessAverage += (state.needs.happiness - state.upbringing.happinessAverage) * weight
        state.upbringing.disciplineAverage += (state.needs.discipline - state.upbringing.disciplineAverage) * weight
        state.averagedTime = total
    }

    private mutating func checkGrowth() -> [PetEvent] {
        guard state.stageAge >= state.stage.duration else { return [] }
        guard let next = state.stage.next else { return [say(goodbye: .oldAge)] }
        state.stage = next
        state.stageAge = 0
        if next == .adult { state.form = state.upbringing.adultForm() }
        return [.evolved(next)]
    }

    private mutating func say(goodbye reason: FarewellReason) -> PetEvent {
        state.farewell = reason
        state.isAsleep = false
        return .farewell(reason)
    }

    // MARK: Care

    /// Starts life: the egg cracks and the baby gets its name.
    mutating func hatch(named name: String) -> [PetEvent] {
        guard state.stage == .egg else { return [] }
        let now = clock.now
        state.name = name
        state.stage = .baby
        state.stageAge = 0
        state.age = 0
        state.bornAt = now
        state.lastUpdate = now
        state.simClock = now
        state.needs = Needs()
        return [.hatched]
    }

    mutating func perform(_ action: CareAction) -> ActionOutcome {
        guard state.stage != .egg, state.isAlive else { return .refused(.notHatched) }
        if state.isAsleep, action != .toggleLights, action != .caress {
            return .refused(.asleep)
        }

        switch action {
        case .meal:
            guard state.needs.hunger < 95 else { return .refused(.full) }
            state.needs[.hunger] += 30
            state.needs[.health] += 2
            state.upbringing.weight += 1

        case .snack:
            state.needs[.happiness] += 12
            state.needs[.hunger] += 8
            state.upbringing.weight += 2
            state.recentSnacks += 1
            if state.recentSnacks > 3 {
                state.needs[.health] -= 12
            }

        case .clean:
            guard state.poops > 0 else { return .refused(.nothingToClean) }
            state.poops = 0
            state.needs[.hygiene] += 10

        case .bath:
            state.needs[.hygiene] = 100
            state.needs[.happiness] += 4

        case .medicine:
            guard state.isSick else {
                state.needs[.happiness] -= 8
                return .refused(.notSick)
            }
            state.isSick = false
            state.needs[.health] = max(state.needs.health, 35) + 35

        case .toggleLights:
            state.lightsOn.toggle()

        case .scold:
            guard state.isTantrum else {
                state.needs[.happiness] -= 10
                return .refused(.unfair)
            }
            state.isTantrum = false
            state.needs[.discipline] += 25

        case .caress:
            state.needs[.happiness] += state.isAsleep ? 1 : 3

        case .played(let won):
            guard state.needs.energy >= 10 else { return .refused(.tooTired) }
            state.needs[.energy] -= 12
            state.needs[.happiness] += won ? 18 : 8
            state.needs[.discipline] += 2
            state.upbringing.weight = max(5, state.upbringing.weight - 2)
        }
        return .done
    }

    /// Whether the snack just eaten was one too many.
    var isOverfed: Bool { state.recentSnacks > 3 }

    var canPlay: Bool {
        state.stage != .egg && state.isAlive && !state.isAsleep && state.needs.energy >= 10
    }

    // MARK: Helpers

    static func isNight(_ date: Date, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= 21 || hour < 7
    }
}
