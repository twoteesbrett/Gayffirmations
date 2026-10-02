import Testing
@testable import Gayffirmations

@MainActor
struct ThemeStoreTests {
    @Test("A saved theme is loaded when a store is created")
    func loadsSavedTheme() {
        let repository = InMemoryThemeRepository(theme: .neutral)

        let store = ThemeStore(repository: repository, defaultTheme: .neutral)

        #expect(store.selectedTheme == .neutral)
    }

    @Test("The default theme is saved on first launch")
    func savesDefaultTheme() {
        let repository = InMemoryThemeRepository()

        let store = ThemeStore(repository: repository, defaultTheme: .neutral)

        #expect(store.selectedTheme == .neutral)
        #expect(repository.theme == .neutral)
    }

    @Test("A theme selection survives recreating the store", arguments: AppTheme.allCases)
    func selectionSurvivesRestart(theme: AppTheme) throws {
        let repository = InMemoryThemeRepository()
        let firstStore = ThemeStore(repository: repository, defaultTheme: .neutral)

        try firstStore.select(theme)
        let restartedStore = ThemeStore(
            repository: repository,
            defaultTheme: .neutral
        )

        #expect(restartedStore.selectedTheme == theme)
    }

    @Test("Reset restores and saves the default theme")
    func reset() throws {
        let repository = InMemoryThemeRepository()
        let store = ThemeStore(repository: repository, defaultTheme: .neutral)

        try store.select(.neutral)
        try store.reset()

        #expect(store.selectedTheme == .neutral)
        #expect(repository.theme == .neutral)
    }

    @Test("A load failure prevents the theme from being overwritten")
    func loadFailurePreventsOverwrite() {
        let repository = FailingThemeRepository()
        let store = ThemeStore(repository: repository, defaultTheme: .neutral)

        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) {
            try store.select(.neutral)
        }
        #expect(store.selectedTheme == .neutral)
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
