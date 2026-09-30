import Testing
@testable import Selfsaid

@MainActor
struct ThemeStoreTests {
    @Test("A saved theme is loaded when a store is created")
    func loadsSavedTheme() {
        let repository = InMemoryThemeRepository(theme: .midnight)

        let store = ThemeStore(repository: repository, defaultTheme: .warm)

        #expect(store.selectedTheme == .midnight)
    }

    @Test("The default theme is saved on first launch")
    func savesDefaultTheme() {
        let repository = InMemoryThemeRepository()

        let store = ThemeStore(repository: repository, defaultTheme: .warm)

        #expect(store.selectedTheme == .warm)
        #expect(repository.theme == .warm)
    }

    @Test("A theme selection survives recreating the store")
    func selectionSurvivesRestart() throws {
        let repository = InMemoryThemeRepository()
        let firstStore = ThemeStore(repository: repository, defaultTheme: .warm)

        try firstStore.select(.playful)
        let restartedStore = ThemeStore(
            repository: repository,
            defaultTheme: .warm
        )

        #expect(restartedStore.selectedTheme == .playful)
    }

    @Test("Reset restores and saves the default theme")
    func reset() throws {
        let repository = InMemoryThemeRepository()
        let store = ThemeStore(repository: repository, defaultTheme: .warm)

        try store.select(.refined)
        try store.reset()

        #expect(store.selectedTheme == .warm)
        #expect(repository.theme == .warm)
    }

    @Test("A load failure prevents the theme from being overwritten")
    func loadFailurePreventsOverwrite() {
        let repository = FailingThemeRepository()
        let store = ThemeStore(repository: repository, defaultTheme: .warm)

        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) {
            try store.select(.midnight)
        }
        #expect(store.selectedTheme == .warm)
        #expect(repository.saveCallCount == 0)
    }
}

private final class InMemoryThemeRepository: ThemeRepository {
    var theme: AppTheme?

    init(theme: AppTheme? = nil) {
        self.theme = theme
    }

    func loadTheme() throws -> AppTheme? {
        theme
    }

    func saveTheme(_ theme: AppTheme) throws {
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
