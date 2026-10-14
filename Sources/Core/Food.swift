import Foundation

// MARK: - Food

/// The three shelves of the menu. Meals fill the belly, fruit keeps the pet
/// healthy, treats cheer it up but too many give it a tummy ache.
enum FoodGroup: String, CaseIterable, Identifiable {
    case meals, fruit, treats
    var id: String { rawValue }

    var foods: [Food] { Food.allCases.filter { $0.group == self } }
}

enum Food: String, Codable, CaseIterable, Identifiable {
    case riceBall, soup, pasta, salad
    case apple, banana, strawberry, watermelon
    case cupcake, cookie, iceCream, donut

    var id: String { rawValue }

    var group: FoodGroup {
        switch self {
        case .riceBall, .soup, .pasta, .salad: return .meals
        case .apple, .banana, .strawberry, .watermelon: return .fruit
        case .cupcake, .cookie, .iceCream, .donut: return .treats
        }
    }

    var emoji: String {
        switch self {
        case .riceBall: return "🍙"
        case .soup: return "🍲"
        case .pasta: return "🍝"
        case .salad: return "🥗"
        case .apple: return "🍎"
        case .banana: return "🍌"
        case .strawberry: return "🍓"
        case .watermelon: return "🍉"
        case .cupcake: return "🧁"
        case .cookie: return "🍪"
        case .iceCream: return "🍦"
        case .donut: return "🍩"
        }
    }

    /// What one serving does to the needs, and to the weight in grams.
    struct Effect: Equatable {
        var hunger: Double = 0
        var happiness: Double = 0
        var health: Double = 0
        var energy: Double = 0
        var weight: Double = 0
    }

    var effect: Effect {
        switch self {
        case .riceBall: return Effect(hunger: 30, health: 2, weight: 1)
        case .soup: return Effect(hunger: 25, health: 6, weight: 1)
        case .pasta: return Effect(hunger: 38, happiness: 3, weight: 2)
        case .salad: return Effect(hunger: 20, health: 8)
        case .apple: return Effect(hunger: 12, happiness: 3, health: 5)
        case .banana: return Effect(hunger: 15, health: 3, energy: 6)
        case .strawberry: return Effect(hunger: 8, happiness: 6, health: 4)
        case .watermelon: return Effect(hunger: 10, happiness: 5, health: 3, energy: 3)
        case .cupcake: return Effect(hunger: 8, happiness: 12, weight: 2)
        case .cookie: return Effect(hunger: 6, happiness: 10, weight: 1)
        case .iceCream: return Effect(hunger: 5, happiness: 15, weight: 2)
        case .donut: return Effect(hunger: 10, happiness: 13, weight: 3)
        }
    }

    var isTreat: Bool { group == .treats }
}

extension PetState {
    /// Every pet is born loving one food. It comes from the pet's id, so it
    /// never changes and needs no room in the save.
    var favoriteFood: Food {
        let bytes = id.uuid
        let all = Food.allCases
        return all[Int(bytes.0 ^ bytes.7 ^ bytes.15) % all.count]
    }
}
