import Foundation
import os
import UserNotifications

final class NotificationService: Sendable {
    static let shared = NotificationService()

    private let didRequestPermission = OSAllocatedUnfairLock(initialState: false)

    private init() {}

    func requestPermission() {
        let alreadyRequested = didRequestPermission.withLock { state in
            defer { state = true }
            return state
        }
        guard !alreadyRequested else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                Log.error("Notification permission error: \(error.localizedDescription)")
            } else {
                Log.info("Notification permission granted: \(granted)")
            }
        }
    }

    func sendAlert(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Log.error("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
}
