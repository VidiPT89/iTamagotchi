@preconcurrency import UserNotifications

/// Books local notifications for the moments the forecast predicts. Text
/// comes through `localize`, so it follows the language chosen in the app
/// rather than the system one.
@MainActor
final class NotificationScheduler {

    var localize: (String) -> String = { $0 }
    private let center = UNUserNotificationCenter.current()
    private static let prefix = "itamagotchi.need."

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func authorizationDenied() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }

    func schedule(_ items: [Forecast.Item], petName: String) {
        cancelAll()
        let now = Date()
        for item in items where item.date.timeIntervalSince(now) > 60 {
            let content = UNMutableNotificationContent()
            let key = "notif.\(item.alert.rawValue)"
            content.title = String(format: localize(key), petName)
            content.body = String(format: localize("\(key).body"), petName)
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: item.date.timeIntervalSince(now), repeats: false)
            center.add(UNNotificationRequest(identifier: Self.prefix + item.alert.rawValue,
                                             content: content, trigger: trigger))
        }
    }

    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: Forecast.Alert.allCases.map { Self.prefix + $0.rawValue })
    }

    func clearDelivered() {
        center.removeAllDeliveredNotifications()
        center.setBadgeCount(0)
    }
}
