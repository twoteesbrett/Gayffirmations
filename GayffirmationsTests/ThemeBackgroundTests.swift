import Foundation
import Testing
import UIKit
@testable import Gayffirmations

@MainActor
struct ThemeBackgroundTests {
    @Test("Photo mode persists, rotates with affirmations and resets with app data")
    func photoModeAndRotation() throws {
        let suite = "gayffirmations.photos.tests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let store = ThemeStore(repository: repository, defaultTheme: .steel, backgroundRepository: repository)
        #expect(store.selectedPhoto != nil)
        #expect(store.backgroundChoice.usesPhoto)
        try store.setUsesPhoto(true)
        let first = UUID()
        store.updateDisplayedAffirmation(first)
        let initialPhoto = store.selectedPhoto?.id
        store.updateDisplayedAffirmation(first)
        #expect(store.selectedPhoto?.id == initialPhoto)
        store.updateDisplayedAffirmation(UUID())
        #expect(store.selectedPhoto?.id != initialPhoto)
        let rotatedPhoto = store.selectedPhoto?.id
        try store.setUsesPhoto(false)
        #expect(store.selectedPhoto == nil)
        try store.setUsesPhoto(true)
        #expect(store.selectedPhoto?.id == rotatedPhoto)
        try store.select(.nature)
        #expect(store.selectedPhoto != nil)
        try store.select(.steel)
        #expect(store.selectedPhoto?.id == rotatedPhoto)
        let restarted = ThemeStore(repository: repository, defaultTheme: .nature, backgroundRepository: repository)
        #expect(restarted.backgroundChoice.usesPhoto)
        #expect(restarted.selectedPhoto != nil)
        try repository.saveAppData(affirmations: [], schedules: [AffirmationSchedule()], theme: .nature, selection: .all)
        store.applyPersistedDefaults()
        #expect(store.backgrounds.isEmpty)
        #expect(try repository.loadThemeBackgrounds().isEmpty)
    }

    @Test("Photo themes default to photos while an explicit opt-out survives switching and restart")
    func defaultPhotoModePreservesOptOut() throws {
        let suite = "gayffirmations.photos.defaults.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let store = ThemeStore(repository: repository, defaultTheme: .refined, backgroundRepository: repository)
        for theme in AppTheme.allCases {
            try store.select(theme)
            #expect(store.backgroundChoice.usesPhoto == !theme.photos.isEmpty)
            #expect((store.selectedPhoto != nil) == !theme.photos.isEmpty)
        }
        try store.select(.steel)
        try store.setUsesPhoto(false)
        try store.select(.nature)
        #expect(store.backgroundChoice.usesPhoto)
        try store.select(.steel)
        #expect(!store.backgroundChoice.usesPhoto)
        let restarted = ThemeStore(repository: repository, defaultTheme: .nature, backgroundRepository: repository)
        #expect(restarted.selectedTheme == .steel)
        #expect(!restarted.backgroundChoice.usesPhoto)
        #expect(restarted.selectedPhoto == nil)
        store.applyPersistedDefaults()
        try store.select(.steel)
        #expect(store.backgroundChoice.usesPhoto)
    }

    @Test("Old fixed photo preferences migrate to rotating photo mode")
    func migratesFixedChoice() throws {
        let data = Data(#"{"usesPhoto":true,"photoID":"removed"}"#.utf8)
        let choice = try JSONDecoder().decode(ThemeBackgroundChoice.self, from: data)
        #expect(choice.usesPhoto)
        let store = ThemeStore(selectedTheme: .refined)
        try store.setUsesPhoto(true)
        #expect(store.selectedPhoto == nil)
        #expect(!store.backgroundChoice.usesPhoto)
    }

    @Test("Enabling photos after viewing a theme without photos advances on the next affirmation")
    func enablesAfterColours() throws {
        let store = ThemeStore(selectedTheme: .refined)
        store.updateDisplayedAffirmation(UUID())
        try store.select(.steel)
        try store.setUsesPhoto(true)
        let photo = store.selectedPhoto?.id
        store.updateDisplayedAffirmation(UUID())
        #expect(store.selectedPhoto?.id != photo)
    }

    @Test("Reversing a swipe returns to the previous photo without a second advance")
    func reversesSwipe() throws {
        let store = ThemeStore(selectedTheme: .steel)
        try store.setUsesPhoto(true)
        let first = UUID()
        let second = UUID()
        store.updateDisplayedAffirmation(first)
        let initialPhoto = store.selectedPhoto?.id
        store.updateDisplayedAffirmation(second, direction: 1)
        #expect(store.selectedPhoto?.id != initialPhoto)
        store.updateDisplayedAffirmation(first, direction: -1)
        #expect(store.selectedPhoto?.id == initialPhoto)
        store.updateDisplayedAffirmation(first)
        #expect(store.selectedPhoto?.id == initialPhoto)
        store.updateDisplayedAffirmation(UUID(), direction: -1)
        #expect(store.selectedPhoto?.id == AppTheme.steel.photos.last?.id)
    }

    @Test("Rotation wraps, handles one photo and ignores empty displays")
    func rotationBoundaries() {
        var rotation = AffirmationPhotoRotation()
        let first = UUID()
        rotation.update(affirmationID: first, photoCount: 3)
        #expect(rotation.photoIndex == 0)
        for expected in [1, 2, 0, 1] {
            rotation.update(affirmationID: UUID(), photoCount: 3)
            #expect(rotation.photoIndex == expected)
        }
        rotation.update(affirmationID: nil, photoCount: 3)
        #expect(rotation.photoIndex == 1)
        rotation.update(affirmationID: UUID(), photoCount: 0)
        #expect(rotation.photoIndex == 1)
        rotation.update(affirmationID: UUID(), photoCount: 1)
        #expect(rotation.photoIndex == 0)
    }

    @Test("Every theme photo has a bundled image")
    func bundledPhotos() {
        for photo in AppTheme.allCases.flatMap({ $0.photos }) {
            #expect(UIImage(named: photo.id) != nil)
        }
    }

    @Test("Nature and Steel save independent photo modes and rotate within their own collection")
    func independentThemeModes() throws {
        let store = ThemeStore(selectedTheme: .nature)
        try store.setUsesPhoto(true)
        let first = UUID()
        store.updateDisplayedAffirmation(first)
        #expect(store.selectedPhoto?.id == AppTheme.nature.photos.first?.id)
        store.updateDisplayedAffirmation(UUID())
        #expect(store.selectedPhoto?.id == AppTheme.nature.photos[1].id)
        try store.select(.steel)
        #expect(store.selectedPhoto != nil)
        try store.setUsesPhoto(true)
        #expect(store.selectedPhoto?.id.hasPrefix("steel-") == true)
        try store.setUsesPhoto(false)
        try store.select(.nature)
        #expect(store.backgroundChoice.usesPhoto)
        #expect(store.selectedPhoto?.id.hasPrefix("nature-") == true)
    }

    @Test("A failed background save preserves the current choice")
    func failedSave() {
        let repository = UnavailableBackgroundRepository()
        let store = ThemeStore(selectedTheme: .steel, backgroundRepository: repository)
        #expect(throws: BackgroundTestError.self) { try store.setUsesPhoto(false) }
        #expect(store.selectedPhoto != nil)
        #expect(store.backgroundChoice.usesPhoto)
        #expect(store.backgrounds.isEmpty)
    }
}

private enum BackgroundTestError: Error { case saveFailed }
private struct UnavailableBackgroundRepository: ThemeBackgroundRepository {
    func loadThemeBackgrounds() throws -> [String: ThemeBackgroundChoice] { [:] }
    func saveThemeBackgrounds(_ backgrounds: [String: ThemeBackgroundChoice]) throws {
        throw BackgroundTestError.saveFailed
    }
}
