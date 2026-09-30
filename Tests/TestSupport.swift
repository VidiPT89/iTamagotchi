import Foundation
@testable import iTamagotchi

/// A clock the tests move forward by hand.
final class ManualClock: Clock {
    var now: Date
    init(_ now: Date) { self.now = now }
    func advance(by seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
}

enum Fixture {
    /// Today at a given local hour, so day and night are predictable.
    static func date(hour: Int, minute: Int = 0) -> Date {
        var parts = Calendar.current.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: 1_750_000_000))
        parts.hour = hour
        parts.minute = minute
        return Calendar.current.date(from: parts)!
    }

    /// A freshly hatched baby at midday, with the clock that drives it.
    static func hatchedEngine(hour: Int = 12) -> (PetEngine, ManualClock) {
        let clock = ManualClock(date(hour: hour))
        var engine = PetEngine(state: PetState(now: clock.now), clock: clock)
        _ = engine.hatch(named: "Pipo")
        return (engine, clock)
    }
}
