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
    func loadSchedule() throws -> AffirmationSchedule?
    func saveSchedule(_ schedule: AffirmationSchedule) throws
}

protocol ThemeRepository {
    func loadTheme() throws -> AppTheme?
    func saveTheme(_ theme: AppTheme) throws
}

protocol AffirmationSelectionRepository {
    func loadAffirmationSelection() throws -> AffirmationSelection?
    func saveAffirmationSelection(_ selection: AffirmationSelection) throws
}

protocol AppDataRepository {
    // A throwing save must leave every section unchanged.
    func saveAppData(
        affirmations: [Affirmation],
        schedule: AffirmationSchedule,
        theme: AppTheme,
        selection: AffirmationSelection
    ) throws
}

protocol ThemeBackgroundRepository {
    func loadThemeBackgrounds() throws -> [String: ThemeBackgroundChoice]
    func saveThemeBackgrounds(_ backgrounds: [String: ThemeBackgroundChoice]) throws
}
