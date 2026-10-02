import Foundation
import Observation

@MainActor
@Observable
final class ThemeStore {
    private(set) var selectedTheme: AppTheme
    private(set) var persistenceErrorMessage: String?

    private(set) var backgrounds: [String: ThemeBackgroundChoice] = [:]
    private var photoRotation = AffirmationPhotoRotation()
    private let backgroundRepository: (any ThemeBackgroundRepository)?

    var backgroundChoice: ThemeBackgroundChoice {
        backgrounds[selectedTheme.rawValue] ?? ThemeBackgroundChoice()
    }

    var selectedPhoto: ThemePhoto? {
        let photos = selectedTheme.photos
        guard backgroundChoice.usesPhoto, !photos.isEmpty else { return nil }
        return photos[photoRotation.photoIndex % photos.count]
    }

    func updateDisplayedAffirmation(_ id: UUID?, direction: Int = 1) {
        photoRotation.update(affirmationID: id, photoCount: selectedTheme.photos.count, direction: direction)
    }

    private let repository: (any ThemeRepository)?
    let defaultTheme: AppTheme

    init(
        selectedTheme: AppTheme = .nature,
        repository: (any ThemeRepository)? = nil,
        backgroundRepository: (any ThemeBackgroundRepository)? = nil
    ) {
        self.selectedTheme = selectedTheme
        self.defaultTheme = selectedTheme
        self.repository = repository
        self.backgroundRepository = backgroundRepository
    }

    init(
        repository: any ThemeRepository,
        defaultTheme: AppTheme,
        backgroundRepository: (any ThemeBackgroundRepository)? = nil
    ) {
        self.repository = repository
        self.backgroundRepository = backgroundRepository
        self.defaultTheme = defaultTheme

        do {
            backgrounds = try backgroundRepository?.loadThemeBackgrounds() ?? [:]
            if let savedTheme = try repository.loadTheme() {
                selectedTheme = savedTheme
            } else {
                selectedTheme = defaultTheme
                try repository.saveTheme(defaultTheme)
            }
        } catch {
            selectedTheme = defaultTheme
            persistenceErrorMessage = error.localizedDescription
        }
    }

    func setUsesPhoto(_ enabled: Bool) throws {
        guard !enabled || !selectedTheme.photos.isEmpty else { return }
        try saveBackground(ThemeBackgroundChoice(usesPhoto: enabled))
    }

    private func saveBackground(_ choice: ThemeBackgroundChoice) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }
        var updated = backgrounds
        updated[selectedTheme.rawValue] = choice
        try backgroundRepository?.saveThemeBackgrounds(updated)
        backgrounds = updated
    }

    func select(_ theme: AppTheme) throws {
        try persist(theme)
    }

    func reset() throws {
        try persist(defaultTheme)
    }

    func applyPersistedDefaults() {
        backgrounds = [:]
        photoRotation = AffirmationPhotoRotation()
        selectedTheme = defaultTheme
    }

    private func persist(_ theme: AppTheme) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }

        try repository?.saveTheme(theme)
        selectedTheme = theme
    }
}
