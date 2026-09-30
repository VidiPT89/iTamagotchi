import Foundation
import SwiftData

/// One line in the life journal. Text is stored as a key plus arguments and
/// rendered at display time, so switching language rewrites the whole diary.
@Model
final class JournalEntry {
    var date: Date
    var petID: UUID
    var key: String
    var arguments: [String]
    var symbol: String

    init(date: Date, petID: UUID, key: String, arguments: [String], symbol: String) {
        self.date = date
        self.petID = petID
        self.key = key
        self.arguments = arguments
        self.symbol = symbol
    }
}

/// A pet that has returned to its planet, kept in the family album.
@Model
final class AlbumEntry {
    var petID: UUID
    var name: String
    var stageRaw: String
    var formRaw: String?
    var bornAt: Date
    var endedAt: Date
    var age: TimeInterval
    var reasonRaw: String

    init(pet: PetState, endedAt: Date) {
        petID = pet.id
        name = pet.name
        stageRaw = pet.stage.rawValue
        formRaw = pet.form?.rawValue
        bornAt = pet.bornAt
        self.endedAt = endedAt
        age = pet.age
        reasonRaw = (pet.farewell ?? .oldAge).rawValue
    }

    var stage: LifeStage { LifeStage(rawValue: stageRaw) ?? .baby }
    var form: AdultForm? { formRaw.flatMap(AdultForm.init(rawValue:)) }
    var reason: FarewellReason { FarewellReason(rawValue: reasonRaw) ?? .oldAge }
}

enum MemoryStore {
    /// Opens the store, falling back to memory so a damaged file can never
    /// stop the app from launching.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([JournalEntry.self, AlbumEntry.self])
        // The album lives with the app; only the small save file is shared
        // with the widget through the App Group.
        // Created up front: on first launch the folder does not exist yet.
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        let disk = ModelConfiguration(schema: schema, groupContainer: .none)
        if let container = try? ModelContainer(for: schema, configurations: disk) {
            return container
        }
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: memory)
        } catch {
            fatalError("Unable to create even an in-memory store: \(error)")
        }
    }
}
