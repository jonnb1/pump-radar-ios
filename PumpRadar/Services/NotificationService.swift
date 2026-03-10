// NotificationService.swift
// PumpRadar
//
// Manages local and remote push notification registration and delivery.
// Local notifications are scheduled when a coin's pump score crosses a
// high-risk threshold while the app is in the foreground.

import Foundation
import UserNotifications
import Combine

// MARK: - NotificationServiceProtocol

protocol NotificationServiceProtocol {
    func requestAuthorization() -> AnyPublisher<Bool, Never>
    func scheduleAlert(for alert: PumpAlert)
    func clearDeliveredNotifications()
}

// MARK: - NotificationService

final class NotificationService: NSObject, NotificationServiceProtocol {

    // MARK: - Shared Instance

    static let shared = NotificationService()

    // MARK: - Initialiser

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    // MARK: - NotificationServiceProtocol

    /// Requests authorization for alerts, sounds, and badges.
    func requestAuthorization() -> AnyPublisher<Bool, Never> {
        Future { promise in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                promise(.success(granted))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Schedules a local notification for the given pump alert.
    func scheduleAlert(for alert: PumpAlert) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 Pump Alert: \(alert.coinSymbol)"
        content.body = alert.message
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = Constants.NotificationCategories.pumpAlert
        content.userInfo = ["alertId": alert.id, "coinId": alert.coinId]

        // Deliver after a brief delay so it appears even in the foreground
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pump-alert-\(alert.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    /// Removes all delivered notifications from Notification Center.
    func clearDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: - Private Helpers

    /// Registers interactive notification categories and actions.
    private func registerCategories() {
        let viewAction = UNNotificationAction(
            identifier: Constants.NotificationActions.viewDetails,
            title: "View Details",
            options: .foreground
        )
        let dismissAction = UNNotificationAction(
            identifier: Constants.NotificationActions.dismiss,
            title: "Dismiss",
            options: .destructive
        )
        let category = UNNotificationCategory(
            identifier: Constants.NotificationCategories.pumpAlert,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Allows notifications to be shown as banners while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Post a notification so interested view controllers can react
        NotificationCenter.default.post(
            name: .pumpAlertTapped,
            object: nil,
            userInfo: response.notification.request.content.userInfo
        )
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pumpAlertTapped = Notification.Name("com.pumpradar.pumpAlertTapped")
}
