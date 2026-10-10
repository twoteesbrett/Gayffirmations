import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct ThemeStoreTests {
    @Test("Swipe previews leave the current photo unchanged and match the committed destination")
    func swipePhotoPreview() throws {
        let store = ThemeStore(selectedTheme: .eden)
        let current = UUID()
        let next = UUID()
        store.updateDisplayedAffirmation(current)
        let original = store.selectedPhoto?.id
        let forward = store.photo(for: next, direction: 1)
        let backward = store.photo(for: next, direction: -1)
        #expect(forward?.id == AppTheme.eden.photos[1].id)
        #expect(backward?.id == AppTheme.eden.photos.last?.id)
        #expect(store.selectedPhoto?.id == original)

        store.updateDisplayedAffirmation(next, direction: -1)
        #expect(store.selectedPhoto?.id == backward?.id)
        try store.setUsesPhoto(false)
        #expect(store.photo(for: current, direction: 1) == nil)
    }

    @Test("A saved theme is loaded when a store is created")
    func loadsSavedTheme() {
        let repository = InMemoryThemeRepository(theme: .steel)

        let store = ThemeStore(repository: repository)

        #expect(store.selectedTheme == .steel)
        #expect(repository.loadCallCount == 1)
        #expect(repository.saveCallCount == 0)
    }

    @Test("The default theme is saved on first launch")
    func savesDefaultTheme() {
        let repository = InMemoryThemeRepository()

        let store = ThemeStore(repository: repository, defaultTheme: .eden)

        #expect(store.selectedTheme == .eden)
        #expect(repository.theme == .eden)
    }

    @Test("A theme selection survives recreating the store", arguments: AppTheme.allCases)
    func selectionSurvivesRestart(theme: AppTheme) throws {
        let repository = InMemoryThemeRepository()
        let firstStore = ThemeStore(repository: repository, defaultTheme: .eden)

        try firstStore.select(theme)
        let restartedStore = ThemeStore(
            repository: repository,
            defaultTheme: .eden
        )

        #expect(restartedStore.selectedTheme == theme)
    }

    @Test("Reset restores and saves the default theme")
    func reset() throws {
        let repository = InMemoryThemeRepository()
        let store = ThemeStore(repository: repository, defaultTheme: .eden)

        try store.select(.disco)
        try store.reset()

        #expect(store.selectedTheme == .eden)
        #expect(repository.theme == .eden)
    }

    @Test("A load failure prevents the theme from being overwritten")
    func loadFailurePreventsOverwrite() {
        let repository = FailingThemeRepository()
        let store = ThemeStore(repository: repository, defaultTheme: .eden)

        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) {
            try store.select(.eden)
        }
        #expect(store.selectedTheme == .eden)
        #expect(repository.saveCallCount == 0)
    }
}

private final class InMemoryThemeRepository: ThemeRepository {
    var theme: AppTheme?
    private(set) var loadCallCount = 0
    private(set) var saveCallCount = 0

    init(theme: AppTheme? = nil) {
        self.theme = theme
    }

    func loadTheme() throws -> AppTheme? {
        loadCallCount += 1
        return theme
    }

    func saveTheme(_ theme: AppTheme) throws {
        saveCallCount += 1
        self.theme = theme
    }
}

private final class FailingThemeRepository: ThemeRepository {
    private(set) var saveCallCount = 0

    func loadTheme() throws -> AppTheme? {
        throw ThemeRepositoryTestError.loadFailed
    }

    func saveTheme(_ theme: AppTheme) throws {
        saveCallCount += 1
    }
}

private enum ThemeRepositoryTestError: Error {
    case loadFailed
}
