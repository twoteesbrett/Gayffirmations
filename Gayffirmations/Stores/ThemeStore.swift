import Foundation
import Observation

@MainActor
@Observable
final class ThemeStore {
    private(set) var selectedTheme: AppTheme
    private(set) var persistenceErrorMessage: String?

    private(set) var backgrounds: [String: ThemeBackgroundChoice] = [:]
    private var imageRotation = AffirmationImageRotation()
    private let backgroundRepository: (any ThemeBackgroundRepository)?

    var backgroundChoice: ThemeBackgroundChoice {
        backgrounds[selectedTheme.rawValue]
            ?? ThemeBackgroundChoice(usesImage: !selectedTheme.images.isEmpty)
    }

    var selectedImage: ThemeImage? {
        let images = selectedTheme.images
        guard backgroundChoice.usesImage, !images.isEmpty else { return nil }
        return images[imageRotation.imageIndex % images.count]
    }

    /// Preview a browsing destination without advancing the committed image rotation.
    func image(for affirmationID: UUID, direction: Int) -> ThemeImage? {
        let images = selectedTheme.images
        guard backgroundChoice.usesImage, !images.isEmpty else { return nil }
        var preview = imageRotation
        preview.update(affirmationID: affirmationID, imageCount: images.count, direction: direction)
        return images[preview.imageIndex % images.count]
    }

    func updateDisplayedAffirmation(_ id: UUID?, direction: Int = 1) {
        imageRotation.update(affirmationID: id, imageCount: selectedTheme.images.count, direction: direction)
    }

    private let repository: (any ThemeRepository)?
    let defaultTheme: AppTheme

    /// Creates an in-memory store for previews and isolated UI tests.
    init(selectedTheme: AppTheme = .eden) {
        self.selectedTheme = selectedTheme
        self.defaultTheme = selectedTheme
        self.repository = nil
        self.backgroundRepository = nil
    }

    /// A repository always loads saved theme and background preferences.
    init(
        repository: any ThemeRepository,
        defaultTheme: AppTheme = .eden,
        backgroundRepository: (any ThemeBackgroundRepository)? = nil
    ) {
        self.repository = repository
        self.backgroundRepository = backgroundRepository
        self.defaultTheme = defaultTheme

        do {
            var loadedBackgrounds = try backgroundRepository?.loadThemeBackgrounds() ?? [:]
            // Keep the former Nature image/gradient preference when migrating to Eden.
            if loadedBackgrounds["eden"] == nil, let previous = loadedBackgrounds.removeValue(forKey: "nature") {
                loadedBackgrounds["eden"] = previous
            }
            backgrounds = loadedBackgrounds
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

    func setUsesImage(_ enabled: Bool) throws {
        guard !enabled || !selectedTheme.images.isEmpty else { return }
        try saveBackground(ThemeBackgroundChoice(usesImage: enabled))
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
        persistenceErrorMessage = nil
        backgrounds = [:]
        imageRotation = AffirmationImageRotation()
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
