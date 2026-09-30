import Foundation

// MARK: - Rooms

enum Room: String, Codable, CaseIterable, Identifiable {
    case living, bedroom, garden
    var id: String { rawValue }
}

// MARK: - Shop

enum ShopCategory: String, CaseIterable, Identifiable {
    case hats, decor, wallpapers
    var id: String { rawValue }
}

struct ShopItem: Identifiable, Equatable {
    let id: String
    let category: ShopCategory
    let price: Int
    /// Decor only: the room it lives in.
    let room: Room?
    /// SF Symbol used for the shop card and, for decor, in the room itself.
    let symbol: String

    static let catalog: [ShopItem] = [
        // Hats are drawn on the pet by the renderer.
        ShopItem(id: "hat.bow", category: .hats, price: 40, room: nil, symbol: "gift.fill"),
        ShopItem(id: "hat.cap", category: .hats, price: 60, room: nil, symbol: "baseball.fill"),
        ShopItem(id: "hat.flower", category: .hats, price: 70, room: nil, symbol: "camera.macro"),
        ShopItem(id: "hat.party", category: .hats, price: 90, room: nil, symbol: "party.popper.fill"),
        ShopItem(id: "hat.headphones", category: .hats, price: 120, room: nil, symbol: "headphones"),
        ShopItem(id: "hat.crown", category: .hats, price: 250, room: nil, symbol: "crown.fill"),

        ShopItem(id: "decor.plant", category: .decor, price: 30, room: .living, symbol: "leaf.fill"),
        ShopItem(id: "decor.lamp", category: .decor, price: 50, room: .living, symbol: "lamp.floor.fill"),
        ShopItem(id: "decor.sofa", category: .decor, price: 110, room: .living, symbol: "sofa.fill"),
        ShopItem(id: "decor.painting", category: .decor, price: 80, room: .living, symbol: "photo.artframe"),
        ShopItem(id: "decor.books", category: .decor, price: 60, room: .bedroom, symbol: "books.vertical.fill"),
        ShopItem(id: "decor.bed", category: .decor, price: 140, room: .bedroom, symbol: "bed.double.fill"),
        ShopItem(id: "decor.teddy", category: .decor, price: 70, room: .bedroom, symbol: "teddybear.fill"),
        ShopItem(id: "decor.tree", category: .decor, price: 90, room: .garden, symbol: "tree.fill"),
        ShopItem(id: "decor.fish", category: .decor, price: 100, room: .garden, symbol: "fish.fill"),
        ShopItem(id: "decor.tent", category: .decor, price: 160, room: .garden, symbol: "tent.fill"),

        ShopItem(id: "wall.warm", category: .wallpapers, price: 0, room: nil, symbol: "square.fill"),
        ShopItem(id: "wall.stripes", category: .wallpapers, price: 60, room: nil, symbol: "line.3.horizontal"),
        ShopItem(id: "wall.dots", category: .wallpapers, price: 60, room: nil, symbol: "circle.grid.3x3.fill"),
        ShopItem(id: "wall.stars", category: .wallpapers, price: 120, room: nil, symbol: "sparkles"),
        ShopItem(id: "wall.forest", category: .wallpapers, price: 120, room: nil, symbol: "mountain.2.fill"),
    ]

    static func item(_ id: String) -> ShopItem? { catalog.first { $0.id == id } }
}

// MARK: - Household

/// Everything the player owns, which outlives any single pet.
struct Household: Codable, Equatable {
    var coins = 50
    var owned: Set<String> = ["wall.warm"]
    var hat: String?
    var wallpaper = "wall.warm"

    enum PurchaseResult: Equatable { case bought, alreadyOwned, notEnoughCoins, unknownItem }

    mutating func buy(_ id: String) -> PurchaseResult {
        guard let item = ShopItem.item(id) else { return .unknownItem }
        guard !owned.contains(id) else { return .alreadyOwned }
        guard coins >= item.price else { return .notEnoughCoins }
        coins -= item.price
        owned.insert(id)
        if item.category == .wallpapers { wallpaper = id }
        if item.category == .hats { hat = id }
        return .bought
    }

    func decor(in room: Room) -> [ShopItem] {
        ShopItem.catalog.filter { $0.room == room && owned.contains($0.id) }
    }

    /// Coins earned from a mini-game score.
    static func reward(forScore score: Int, won: Bool) -> Int {
        max(1, score / 2) + (won ? 10 : 0)
    }
}

// MARK: - Stats

struct LifetimeStats: Codable, Equatable {
    var petsRaised = 0
    var meals = 0
    var snacks = 0
    var baths = 0
    var cleanings = 0
    var medicines = 0
    var caresses = 0
    var gamesPlayed = 0
    var gamesWon = 0
    var coinsEarned = 0
    var longestLife: TimeInterval = 0
}

// MARK: - Achievements

enum Achievement: String, CaseIterable, Identifiable, Codable {
    case firstHatch, firstSteps, grownUp, goldenYears, rareForm
    case tidy, gamer, saver, shopper, weekOld, perfectCare, fashion

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .firstHatch: return "oval.portrait.fill"
        case .firstSteps: return "figure.walk"
        case .grownUp: return "arrow.up.forward.circle.fill"
        case .goldenYears: return "hourglass"
        case .rareForm: return "sparkles"
        case .tidy: return "bubbles.and.sparkles.fill"
        case .gamer: return "gamecontroller.fill"
        case .saver: return "dollarsign.circle.fill"
        case .shopper: return "bag.fill"
        case .weekOld: return "calendar"
        case .perfectCare: return "heart.circle.fill"
        case .fashion: return "crown.fill"
        }
    }

    func isMet(pet: PetState, household: Household, stats: LifetimeStats) -> Bool {
        switch self {
        case .firstHatch: return stats.petsRaised >= 1
        case .firstSteps: return pet.stage >= .child
        case .grownUp: return pet.stage >= .adult
        case .goldenYears: return pet.stage == .senior
        case .rareForm: return pet.form?.isRare == true
        case .tidy: return stats.cleanings >= 20
        case .gamer: return stats.gamesWon >= 10
        case .saver: return household.coins >= 300
        case .shopper: return household.owned.count >= 6
        case .weekOld: return pet.ageInDays >= 7
        case .perfectCare:
            return pet.stage != .egg && NeedKind.allCases.filter { $0 != .discipline }
                .allSatisfy { pet.needs[$0] >= 90 }
        case .fashion: return household.hat != nil
        }
    }
}

// MARK: - Save file

struct GameSave: Codable, Equatable {
    var pet: PetState
    var household = Household()
    var stats = LifetimeStats()
    var achievements: [String: Date] = [:]
    var hasOnboarded = false

    init(now: Date) {
        pet = PetState(now: now, seed: UInt64(now.timeIntervalSince1970))
    }

    /// Whether a save from another device should replace this one: the
    /// most recently played pet wins, a fresh egg never overwrites a pet,
    /// and a pet already said goodbye to never comes back over a new egg.
    func shouldAdopt(_ remote: GameSave) -> Bool {
        guard remote != self, remote.hasOnboarded else { return false }
        if !hasOnboarded { return true }
        if pet.stage == .egg, remote.pet.stage != .egg { return remote.pet.isAlive }
        if remote.pet.stage == .egg, pet.stage != .egg, pet.isAlive { return false }
        return remote.pet.lastUpdate > pet.lastUpdate
    }

    /// Unlocks anything newly earned and returns it, for the toast.
    mutating func refreshAchievements(now: Date) -> [Achievement] {
        var fresh: [Achievement] = []
        for achievement in Achievement.allCases where achievements[achievement.rawValue] == nil {
            if achievement.isMet(pet: pet, household: household, stats: stats) {
                achievements[achievement.rawValue] = now
                fresh.append(achievement)
            }
        }
        return fresh
    }
}
