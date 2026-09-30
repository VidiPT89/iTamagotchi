import Foundation

/// Looks ahead to find when each need will next want attention, so local
/// notifications can be booked for the right moment instead of guessed.
enum Forecast {

    enum Alert: String, CaseIterable {
        case hungry, bored, dirty, sleepy, sick
    }

    struct Item: Equatable {
        let alert: Alert
        let date: Date
    }

    /// Runs a copy of the pet forward (the real one is never touched) and
    /// records the first moment each alert condition becomes true.
    static func upcoming(for pet: PetState, speed: Double, from now: Date,
                         horizon: TimeInterval = 24 * 3600) -> [Item] {
        guard pet.stage != .egg, pet.isAlive, speed > 0 else { return [] }
        var engine = PetEngine(state: pet, speed: speed)
        let step: TimeInterval = 10 * 60
        var elapsed: TimeInterval = 0
        var found: [Alert: Date] = [:]
        var active = Set(Alert.allCases.filter { isActive($0, pet) })

        while elapsed < horizon, engine.state.isAlive {
            _ = engine.simulate(seconds: step)
            elapsed += step
            for alert in Alert.allCases where found[alert] == nil {
                let on = isActive(alert, engine.state)
                // Only a need that goes from fine to not-fine is worth a ping.
                if on, !active.contains(alert) {
                    found[alert] = now.addingTimeInterval(elapsed / speed)
                }
                if on { active.insert(alert) } else { active.remove(alert) }
            }
        }
        return found.map { Item(alert: $0.key, date: $0.value) }.sorted { $0.date < $1.date }
    }

    static func isActive(_ alert: Alert, _ pet: PetState) -> Bool {
        switch alert {
        case .hungry: return pet.needs.hunger < 20
        case .bored: return pet.needs.happiness < 20
        case .dirty: return pet.poops >= 2
        case .sleepy: return pet.isAsleep && pet.lightsOn
        case .sick: return pet.isSick
        }
    }
}

// MARK: - Weather

/// Purely visual weather for the window and garden. Deterministic, so every
/// screen agrees and it changes on its own every few hours.
enum Weather: String, CaseIterable {
    case sunny, cloudy, rainy, snowy

    static func at(_ date: Date, calendar: Calendar = .current) -> Weather {
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let block = calendar.component(.hour, from: date) / 6
        let month = calendar.component(.month, from: date)
        var rng = SplitMix64(seed: UInt64(day * 4 + block))
        let roll = Int(rng.next() % 100)
        let winter = month == 12 || month <= 2
        if roll < 50 { return .sunny }
        if roll < 75 { return .cloudy }
        if roll < 92 || !winter { return .rainy }
        return .snowy
    }
}

/// Where the sun is: 0 at midnight, 0.5 at noon.
enum DayCycle {
    static func phase(_ date: Date, calendar: Calendar = .current) -> Double {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = Double((parts.hour ?? 0) * 60 + (parts.minute ?? 0))
        return minutes / 1440
    }

    /// 0 in the dark of night, 1 in full daylight, with soft dawns and dusks.
    static func daylight(_ date: Date, calendar: Calendar = .current) -> Double {
        let hour = phase(date, calendar: calendar) * 24
        switch hour {
        case ..<6: return 0
        case 6..<8: return (hour - 6) / 2
        case 8..<19: return 1
        case 19..<21: return 1 - (hour - 19) / 2
        default: return 0
        }
    }
}
