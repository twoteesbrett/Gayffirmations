import Foundation

struct PersistenceUnavailableError: LocalizedError {
    let reason: String

    var errorDescription: String? {
        "Saved data is unavailable. \(reason)"
    }
}

protocol AffirmationRepository {
    func loadAffirmations() throws -> [Affirmation]?
    func saveAffirmations(_ affirmations: [Affirmation]) throws
}

protocol ScheduleRepository {
    func loadSchedules() throws -> [AffirmationSchedule]?
    func saveSchedules(_ schedules: [AffirmationSchedule]) throws
    func loadNotificationSound() throws -> NotificationSound?
    func saveNotificationSound(_ sound: NotificationSound) throws
}

protocol ThemeRepository {
    func loadTheme() throws -> AppTheme?
    func saveTheme(_ theme: AppTheme) throws
}

protocol AffirmationSelectionRepository {
    func loadAffirmationSelection() throws -> AffirmationSelection?
    func saveAffirmationSelection(_ selection: AffirmationSelection) throws
}

protocol PersonalizationRepository {
    func loadName() throws -> String?
    func saveName(_ name: String) throws
}

protocol AppDataRepository {
    // A throwing save must leave every section unchanged.
    func saveAppData(
        affirmations: [Affirmation],
        schedules: [AffirmationSchedule],
        theme: AppTheme,
        selection: AffirmationSelection,
        preservingExistingData: Bool
    ) throws
}

extension AppDataRepository {
    func saveAppData(
        affirmations: [Affirmation], schedules: [AffirmationSchedule],
        theme: AppTheme, selection: AffirmationSelection
    ) throws {
        try saveAppData(affirmations: affirmations, schedules: schedules,
                        theme: theme, selection: selection, preservingExistingData: false)
    }
}

protocol ThemeBackgroundRepository {
    func loadThemeBackgrounds() throws -> [String: ThemeBackgroundChoice]
    func saveThemeBackgrounds(_ backgrounds: [String: ThemeBackgroundChoice]) throws
}
