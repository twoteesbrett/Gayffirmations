import Foundation
import Observation

@MainActor
@Observable
final class ThemeStore {
    /// Saved default; a schedule can supply a display theme without changing it.
    private(set) var selectedTheme: AppTheme
    private(set) var persistenceErrorMessage: String?

    private static let appearanceKey = "appearance"
    private(set) var backgroundChoice = ThemeBackgroundChoice(usesImage: true)
    private var imageRotation = AffirmationImageRotation()
    private let backgroundRepository: (any ThemeBackgroundRepository)?

    var selectedImage: ThemeImage? {
        selectedImage(for: selectedTheme)
    }

    func selectedImage(for theme: AppTheme) -> ThemeImage? {
        let images = theme.images
        guard backgroundChoice.usesImage, !images.isEmpty else { return nil }
        return images[imageRotation.imageIndex % images.count]
    }

    /// Preview a browsing destination without advancing the committed image rotation.
    func image(for affirmationID: UUID, direction: Int, theme: AppTheme? = nil) -> ThemeImage? {
        let theme = theme ?? selectedTheme
        let images = theme.images
        guard backgroundChoice.usesImage, !images.isEmpty else { return nil }
        var preview = imageRotation
        preview.update(affirmationID: affirmationID, imageCount: images.count, direction: direction)
        return images[preview.imageIndex % images.count]
    }

    func updateDisplayedAffirmation(_ id: UUID?, direction: Int = 1, theme: AppTheme? = nil) {
        imageRotation.update(affirmationID: id, imageCount: (theme ?? selectedTheme).images.count, direction: direction)
    }

    private let repository: (any ThemeRepository)?
    let defaultTheme: AppTheme

    /// Creates an in-memory store for previews and isolated UI tests.
    init(selectedTheme: AppTheme = .outAndAbout) {
        self.selectedTheme = selectedTheme
        self.defaultTheme = selectedTheme
        self.repository = nil
        self.backgroundRepository = nil
    }

    /// A repository always loads saved theme and background preferences.
    init(
        repository: any ThemeRepository,
        defaultTheme: AppTheme = .outAndAbout,
        backgroundRepository: (any ThemeBackgroundRepository)? = nil
    ) {
        self.repository = repository
        self.backgroundRepository = backgroundRepository
        self.defaultTheme = defaultTheme

        do {
            let backgrounds = try backgroundRepository?.loadThemeBackgrounds() ?? [:]
            if let savedTheme = try repository.loadTheme() {
                selectedTheme = savedTheme
            } else {
                selectedTheme = defaultTheme
                try repository.saveTheme(defaultTheme)
            }

            if let appearance = backgrounds[Self.appearanceKey] {
                backgroundChoice = appearance
            } else if backgrounds.keys.contains(where: { AppTheme(rawValue: $0) != nil }) {
                // Use the saved default theme's preferences when consolidating old settings.
                let appearance = backgrounds[selectedTheme.rawValue] ?? backgroundChoice
                try backgroundRepository?.saveThemeBackgrounds([Self.appearanceKey: appearance])
                backgroundChoice = appearance
            }
        } catch {
            selectedTheme = defaultTheme
            persistenceErrorMessage = error.localizedDescription
        }
    }

    func setUsesImage(_ enabled: Bool) throws {
        var choice = backgroundChoice
        choice.usesImage = enabled
        try saveBackground(choice)
    }

    func setImageDimming(_ value: Double) throws {
        var choice = backgroundChoice
        let adjustment = ThemeBackgroundChoice.snappedDimming(value)
        choice.imageDimming = adjustment == 0 ? nil : adjustment
        try saveBackground(choice)
    }

    func setOutlinesText(_ enabled: Bool) throws {
        var choice = backgroundChoice
        choice.outlinesText = enabled ? true : nil
        try saveBackground(choice)
    }

    private func saveBackground(_ choice: ThemeBackgroundChoice) throws {
        if let persistenceErrorMessage {
            throw PersistenceUnavailableError(reason: persistenceErrorMessage)
        }
        try backgroundRepository?.saveThemeBackgrounds([Self.appearanceKey: choice])
        backgroundChoice = choice
    }

    func select(_ theme: AppTheme) throws {
        try persist(theme)
    }

    func reset() throws {
        try persist(defaultTheme)
    }

    func applyPersistedDefaults() {
        persistenceErrorMessage = nil
        backgroundChoice = ThemeBackgroundChoice(usesImage: true)
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
