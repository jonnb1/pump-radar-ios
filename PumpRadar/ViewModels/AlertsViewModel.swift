// AlertsViewModel.swift
// PumpRadar
//
// Loads pump alerts from the API, manages read/unread state,
// and schedules local notifications for high-severity alerts.

import Foundation
import Combine

// MARK: - AlertsViewModel

@MainActor
final class AlertsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var alerts: [PumpAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var unreadCount: Int { alerts.filter { !$0.isRead }.count }
    var hasUnread: Bool { unreadCount > 0 }

    // MARK: - Dependencies

    private let apiService: APIServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialiser

    init(
        apiService: APIServiceProtocol = APIService(),
        notificationService: NotificationServiceProtocol = NotificationService.shared
    ) {
        self.apiService = apiService
        self.notificationService = notificationService
    }

    // MARK: - Actions

    /// Fetches all alerts from the API and schedules notifications
    /// for any unread high/critical-severity items.
    func loadAlerts() {
        isLoading = true
        errorMessage = nil
        apiService.fetchAlerts()
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                    #if DEBUG
                    if self?.alerts.isEmpty == true {
                        self?.alerts = [PumpAlert.preview, PumpAlert.previewRead]
                    }
                    #endif
                }
            } receiveValue: { [weak self] newAlerts in
                guard let self else { return }
                self.alerts = newAlerts.sorted { $0.createdAt > $1.createdAt }
                // Schedule local notifications for new unread high/critical alerts
                newAlerts
                    .filter { !$0.isRead && ($0.severity == .high || $0.severity == .critical) }
                    .forEach { self.notificationService.scheduleAlert(for: $0) }
            }
            .store(in: &cancellables)
    }

    /// Marks a single alert as read both locally and on the server.
    func markAsRead(_ alert: PumpAlert) {
        guard !alert.isRead else { return }
        // Optimistic update
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index].isRead = true
        }
        apiService.markAlertRead(id: alert.id)
            .sink { [weak self] completion in
                if case .failure = completion {
                    // Revert on failure
                    if let index = self?.alerts.firstIndex(where: { $0.id == alert.id }) {
                        self?.alerts[index].isRead = false
                    }
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    /// Marks all alerts as read.
    func markAllAsRead() {
        alerts.indices.forEach { alerts[$0].isRead = true }
        alerts.forEach { alert in
            apiService.markAlertRead(id: alert.id)
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }
}
