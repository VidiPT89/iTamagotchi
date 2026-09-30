import Foundation

/// Mirrors the saved game in iCloud key-value storage, so the same pet lives
/// on every iPhone and iPad signed in to the same Apple Account. The album
/// and journal stay on each device.
@MainActor
final class CloudSync {

    private let store = NSUbiquitousKeyValueStore.default
    private static let key = "game.save.v1"
    private var observer: NSObjectProtocol?

    /// Called on the main queue when another device pushes a newer save.
    var onRemoteChange: ((GameSave) -> Void)?

    func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, let remote = self.pull() else { return }
                    self.onRemoteChange?(remote)
                }
            }
        store.synchronize()
    }

    func pull() -> GameSave? {
        guard let data = store.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(GameSave.self, from: data)
    }

    func push(_ save: GameSave) {
        guard let data = try? JSONEncoder().encode(save) else { return }
        store.set(data, forKey: Self.key)
    }
}
