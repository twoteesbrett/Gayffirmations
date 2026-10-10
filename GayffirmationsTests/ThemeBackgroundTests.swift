import Foundation
import Testing
import UIKit
@testable import Gayffirmations

@MainActor
struct ThemeBackgroundTests {
    @Test("Nature's gradient preference migrates to Eden across restarts")
    func migratesNatureBackground() throws {
        let suite = "gayffirmations.eden.migration.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        try repository.saveThemeBackgrounds(["nature": ThemeBackgroundChoice(usesImage: false)])
        for _ in 0..<2 {
            let store = ThemeStore(repository: repository, defaultTheme: .eden, backgroundRepository: repository)
            #expect(!store.backgroundChoice.usesImage)
            #expect(store.selectedImage == nil)
            try store.setUsesImage(false)
        }
        #expect(try repository.loadThemeBackgrounds()["eden"]?.usesImage == false)
    }

    @Test("Image mode persists, rotates with affirmations and resets with app data")
    func imageModeAndRotation() throws {
        let suite = "gayffirmations.images.tests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let store = ThemeStore(repository: repository, defaultTheme: .steel, backgroundRepository: repository)
        #expect(store.selectedImage != nil)
        #expect(store.backgroundChoice.usesImage)
        try store.setUsesImage(true)
        let first = UUID()
        store.updateDisplayedAffirmation(first)
        let initialImage = store.selectedImage?.id
        store.updateDisplayedAffirmation(first)
        #expect(store.selectedImage?.id == initialImage)
        store.updateDisplayedAffirmation(UUID())
        #expect(store.selectedImage?.id != initialImage)
        let rotatedImage = store.selectedImage?.id
        try store.setUsesImage(false)
        #expect(store.selectedImage == nil)
        try store.setUsesImage(true)
        #expect(store.selectedImage?.id == rotatedImage)
        try store.select(.eden)
        #expect(store.selectedImage != nil)
        try store.select(.steel)
        #expect(store.selectedImage?.id == rotatedImage)
        let restarted = ThemeStore(repository: repository, defaultTheme: .eden, backgroundRepository: repository)
        #expect(restarted.backgroundChoice.usesImage)
        #expect(restarted.selectedImage != nil)
        try repository.saveAppData(affirmations: [], schedules: [AffirmationSchedule()], theme: .eden, selection: .all)
        store.applyPersistedDefaults()
        #expect(store.backgrounds.isEmpty)
        #expect(try repository.loadThemeBackgrounds().isEmpty)
    }

    @Test("Image themes default to images while an explicit opt-out survives switching and restart")
    func defaultImageModePreservesOptOut() throws {
        let suite = "gayffirmations.images.defaults.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let store = ThemeStore(repository: repository, defaultTheme: .eden, backgroundRepository: repository)
        for theme in AppTheme.allCases {
            try store.select(theme)
            #expect(store.backgroundChoice.usesImage == !theme.images.isEmpty)
            #expect((store.selectedImage != nil) == !theme.images.isEmpty)
        }
        try store.select(.steel)
        try store.setUsesImage(false)
        try store.select(.eden)
        #expect(store.backgroundChoice.usesImage)
        try store.select(.steel)
        #expect(!store.backgroundChoice.usesImage)
        let restarted = ThemeStore(repository: repository, defaultTheme: .eden, backgroundRepository: repository)
        #expect(restarted.selectedTheme == .steel)
        #expect(!restarted.backgroundChoice.usesImage)
        #expect(restarted.selectedImage == nil)
        store.applyPersistedDefaults()
        try store.select(.steel)
        #expect(store.backgroundChoice.usesImage)
    }

    @Test("Old fixed image preferences migrate to rotating image mode")
    func migratesFixedChoice() throws {
        let data = Data(#"{"usesPhoto":true,"photoID":"removed"}"#.utf8)
        let choice = try JSONDecoder().decode(ThemeBackgroundChoice.self, from: data)
        #expect(choice.usesImage)
        let optOut = try JSONDecoder().decode(
            ThemeBackgroundChoice.self, from: Data(#"{"usesPhoto":false}"#.utf8)
        )
        #expect(!optOut.usesImage)
        let encoded = try JSONEncoder().encode(optOut)
        let stored = try JSONSerialization.jsonObject(with: encoded) as? [String: Bool]
        #expect(stored?["usesPhoto"] == false)
    }

    @Test("Enabling images after viewing a colour background advances on the next affirmation")
    func enablesAfterColours() throws {
        let store = ThemeStore(selectedTheme: .eden)
        try store.setUsesImage(false)
        #expect(store.selectedImage == nil)
        store.updateDisplayedAffirmation(UUID())
        try store.select(.steel)
        try store.setUsesImage(true)
        let image = store.selectedImage?.id
        store.updateDisplayedAffirmation(UUID())
        #expect(store.selectedImage?.id != image)
    }

    @Test("Reversing a swipe returns to the previous image without a second advance")
    func reversesSwipe() throws {
        let store = ThemeStore(selectedTheme: .steel)
        try store.setUsesImage(true)
        let first = UUID()
        let second = UUID()
        store.updateDisplayedAffirmation(first)
        let initialImage = store.selectedImage?.id
        store.updateDisplayedAffirmation(second, direction: 1)
        #expect(store.selectedImage?.id != initialImage)
        store.updateDisplayedAffirmation(first, direction: -1)
        #expect(store.selectedImage?.id == initialImage)
        store.updateDisplayedAffirmation(first)
        #expect(store.selectedImage?.id == initialImage)
        store.updateDisplayedAffirmation(UUID(), direction: -1)
        #expect(store.selectedImage?.id == AppTheme.steel.images.last?.id)
    }

    @Test("Rotation wraps, handles one image and ignores empty displays")
    func rotationBoundaries() {
        var rotation = AffirmationImageRotation()
        let first = UUID()
        rotation.update(affirmationID: first, imageCount: 3)
        #expect(rotation.imageIndex == 0)
        for expected in [1, 2, 0, 1] {
            rotation.update(affirmationID: UUID(), imageCount: 3)
            #expect(rotation.imageIndex == expected)
        }
        rotation.update(affirmationID: nil, imageCount: 3)
        #expect(rotation.imageIndex == 1)
        rotation.update(affirmationID: UUID(), imageCount: 0)
        #expect(rotation.imageIndex == 1)
        rotation.update(affirmationID: UUID(), imageCount: 1)
        #expect(rotation.imageIndex == 0)
    }

    @Test("Every theme image has a bundled image")
    func bundledImages() {
        for image in AppTheme.allCases.flatMap({ $0.images }) {
            #expect(UIImage(named: image.id) != nil)
        }
    }

    @Test("Eden and Steel save independent image modes and rotate within their own collection")
    func independentThemeModes() throws {
        let store = ThemeStore(selectedTheme: .eden)
        try store.setUsesImage(true)
        let first = UUID()
        store.updateDisplayedAffirmation(first)
        #expect(store.selectedImage?.id == AppTheme.eden.images.first?.id)
        store.updateDisplayedAffirmation(UUID())
        #expect(store.selectedImage?.id == AppTheme.eden.images[1].id)
        try store.select(.steel)
        #expect(store.selectedImage != nil)
        try store.setUsesImage(true)
        #expect(store.selectedImage?.id.hasPrefix("steel-") == true)
        try store.setUsesImage(false)
        try store.select(.eden)
        #expect(store.backgroundChoice.usesImage)
        #expect(store.selectedImage?.id.hasPrefix("eden-") == true)
    }

    @Test("A failed background save preserves the current choice")
    func failedSave() {
        let repository = UnavailableBackgroundRepository()
        let store = ThemeStore(repository: repository, defaultTheme: .steel, backgroundRepository: repository)
        #expect(throws: BackgroundTestError.self) { try store.setUsesImage(false) }
        #expect(store.selectedImage != nil)
        #expect(store.backgroundChoice.usesImage)
        #expect(store.backgrounds.isEmpty)
    }
}

private enum BackgroundTestError: Error { case saveFailed }
private struct UnavailableBackgroundRepository: ThemeBackgroundRepository, ThemeRepository {
    func loadTheme() throws -> AppTheme? { .steel }
    func saveTheme(_ theme: AppTheme) throws { throw BackgroundTestError.saveFailed }
    func loadThemeBackgrounds() throws -> [String: ThemeBackgroundChoice] { [:] }
    func saveThemeBackgrounds(_ backgrounds: [String: ThemeBackgroundChoice]) throws {
        throw BackgroundTestError.saveFailed
    }
}
