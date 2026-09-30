import Foundation

// MARK: - Life stages

enum LifeStage: String, Codable, CaseIterable, Comparable {
    case egg, baby, child, teen, adult, senior

    /// Simulated seconds the pet spends in this stage before moving on.
    /// The egg waits for the player, so it has no clock of its own.
    var duration: TimeInterval {
        switch self {
        case .egg: return .infinity
        case .baby: return 60 * 60
        case .child: return 24 * 60 * 60
        case .teen: return 2 * 24 * 60 * 60
        case .adult: return 4 * 24 * 60 * 60
        case .senior: return 3 * 24 * 60 * 60
        }
    }

    var next: LifeStage? {
        let all = LifeStage.allCases
        guard let index = all.firstIndex(of: self), index + 1 < all.count else { return nil }
        return all[index + 1]
    }

    private var order: Int { LifeStage.allCases.firstIndex(of: self) ?? 0 }

    static func < (lhs: LifeStage, rhs: LifeStage) -> Bool { lhs.order < rhs.order }
}

// MARK: - Needs

enum NeedKind: String, Codable, CaseIterable, Identifiable {
    case hunger, happiness, energy, hygiene, health, discipline

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .hunger: return "fork.knife"
        case .happiness: return "heart.fill"
        case .energy: return "bolt.fill"
        case .hygiene: return "bubbles.and.sparkles.fill"
        case .health: return "cross.case.fill"
        case .discipline: return "star.fill"
        }
    }
}

/// Every need runs from 0 (empty) to 100 (fully satisfied).
struct Needs: Codable, Equatable {
    var hunger: Double = 80
    var happiness: Double = 80
    var energy: Double = 90
    var hygiene: Double = 100
    var health: Double = 100
    var discipline: Double = 20

    subscript(kind: NeedKind) -> Double {
        get {
            switch kind {
            case .hunger: return hunger
            case .happiness: return happiness
            case .energy: return energy
            case .hygiene: return hygiene
            case .health: return health
            case .discipline: return discipline
            }
        }
        set {
            let value = min(100, max(0, newValue))
            switch kind {
            case .hunger: hunger = value
            case .happiness: happiness = value
            case .energy: energy = value
            case .hygiene: hygiene = value
            case .health: health = value
            case .discipline: discipline = value
            }
        }
    }

    var average: Double {
        (hunger + happiness + energy + hygiene + health) / 5
    }
}

// MARK: - Adult forms

/// The eight grown-up shapes. Which one appears depends on how the pet was
/// raised through childhood and adolescence.
enum AdultForm: String, Codable, CaseIterable, Identifiable {
    case astro, luna, pudding, sunny, nimbus, ember, pebble, grumble

    var id: String { rawValue }

    var isRare: Bool { self == .astro || self == .luna }
}

/// The numbers that decide the adult form, gathered while growing up.
struct Upbringing: Codable, Equatable {
    var careMistakes = 0
    var lightMistakes = 0
    var happinessAverage: Double = 50
    var disciplineAverage: Double = 20
    var weight: Double = 10

    func adultForm() -> AdultForm {
        if careMistakes <= 1, disciplineAverage >= 80, happinessAverage >= 80 { return .astro }
        if careMistakes <= 2, lightMistakes == 0, disciplineAverage >= 60 { return .luna }
        if weight >= 30 { return .pudding }
        if careMistakes <= 3, happinessAverage >= 65 { return .sunny }
        if careMistakes <= 6 { return disciplineAverage >= 50 ? .nimbus : .ember }
        return happinessAverage >= 35 ? .pebble : .grumble
    }
}

// MARK: - Mood

enum Mood: String, Codable, CaseIterable {
    case happy, content, sad, hungry, sleepy, sleeping, sick, angry, dirty

    /// How much the pet bounces around in this mood (0 = still).
    var liveliness: Double {
        switch self {
        case .happy: return 1
        case .content: return 0.6
        case .angry: return 0.8
        case .dirty, .hungry: return 0.35
        case .sad, .sleepy: return 0.2
        case .sick: return 0.1
        case .sleeping: return 0
        }
    }
}

// MARK: - Farewell

enum FarewellReason: String, Codable {
    case oldAge, neglect
}

// MARK: - Pet state

struct PetState: Codable, Equatable {
    var id = UUID()
    var name = ""
    var stage: LifeStage = .egg
    var form: AdultForm?
    var needs = Needs()

    /// Real time of the last simulation step.
    var lastUpdate: Date
    /// Simulated wall clock. Matches real time at normal speed and runs ahead
    /// of it in demo mode, which is what drives the day and night cycle.
    var simClock: Date
    var bornAt: Date
    var age: TimeInterval = 0
    var stageAge: TimeInterval = 0

    var upbringing = Upbringing()
    var poops = 0
    var isSick = false
    var isAsleep = false
    var lightsOn = true
    var isTantrum = false
    var farewell: FarewellReason?

    // Internal timers, all in simulated seconds.
    var poopTimer: TimeInterval = 0
    var tantrumTimer: TimeInterval = 0
    var nextTantrumIn: TimeInterval = 4 * 3600
    var tantrumAge: TimeInterval = 0
    var hungerEmptyFor: TimeInterval = 0
    var happinessEmptyFor: TimeInterval = 0
    var lightsOnWhileAsleepFor: TimeInterval = 0
    var lightMistakeCounted = false
    var healthEmptyFor: TimeInterval = 0
    var recentSnacks: Double = 0
    var averagedTime: TimeInterval = 0
    var rng = SplitMix64(seed: 0x17A_6070)

    init(now: Date, seed: UInt64 = 0x17A_6070) {
        lastUpdate = now
        simClock = now
        bornAt = now
        rng = SplitMix64(seed: seed)
    }

    var isAlive: Bool { farewell == nil }

    var mood: Mood {
        if isAsleep { return .sleeping }
        if isSick { return .sick }
        if isTantrum { return .angry }
        if needs.hunger < 25 { return .hungry }
        if needs.energy < 20 { return .sleepy }
        if poops >= 2 || needs.hygiene < 25 { return .dirty }
        if needs.happiness < 30 { return .sad }
        if needs.average >= 70 { return .happy }
        return .content
    }

    /// True when something needs doing right now; drives the attention badge.
    var needsAttention: Bool {
        guard stage != .egg, isAlive else { return false }
        return isSick || isTantrum || poops > 0 || needs.hunger < 25
            || needs.happiness < 25 || (isAsleep && lightsOn)
    }

    var ageInDays: Int { Int(age / 86_400) }
}

// MARK: - Events

/// Things that happen to the pet. The UI turns them into effects and sounds,
/// the journal keeps the memorable ones.
enum PetEvent: Equatable {
    case hatched
    case evolved(LifeStage)
    case pooped
    case gotSick
    case recovered
    case fellAsleep
    case wokeUp
    case tantrumStarted
    case tantrumIgnored
    case careMistake
    case lightsMistake
    case ateTooMuch
    case farewell(FarewellReason)

    /// Worth a line in the life journal.
    var isMemorable: Bool {
        switch self {
        case .hatched, .evolved, .gotSick, .recovered, .farewell, .ateTooMuch: return true
        default: return false
        }
    }
}

// MARK: - Randomness

/// A tiny seeded generator stored inside the pet, so a replay of the same
/// state always gives the same tantrums and the tests stay deterministic.
struct SplitMix64: RandomNumberGenerator, Codable, Equatable {
    private(set) var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
