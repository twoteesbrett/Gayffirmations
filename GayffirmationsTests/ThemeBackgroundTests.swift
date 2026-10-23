import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Gayffirmations

@MainActor
struct ThemeBackgroundTests {
    @Test("Panning reveals the full source image with asymmetric focal point bounds")
    func fullSourcePanBounds() {
        let imageSize = CGSize(width: 2000, height: 1000)
        let viewport = CGSize(width: 100, height: 200)
        let focalPoint = UnitPoint(x: 0.85, y: 0.5)
        let right = ImageViewport.constrainedOffset(CGSize(width: 100, height: 100), zoom: 2,
            imageSize: imageSize, viewport: viewport, focalPoint: focalPoint)
        let left = ImageViewport.constrainedOffset(CGSize(width: -100, height: -100), zoom: 2,
            imageSize: imageSize, viewport: viewport, focalPoint: focalPoint)
        #expect(abs(right.width - 5.6) < 0.0001)
        #expect(abs(left.width + 1.4) < 0.0001)
        #expect(right.height == 0.5)
        #expect(left.height == -0.5)
        let unzoomedRight = ImageViewport.constrainedOffset(right, zoom: 1, imageSize: imageSize,
            viewport: viewport, focalPoint: focalPoint)
        let unzoomedLeft = ImageViewport.constrainedOffset(left, zoom: 1, imageSize: imageSize,
            viewport: viewport, focalPoint: focalPoint)
        #expect(abs(unzoomedRight.width - 2.55) < 0.0001)
        #expect(abs(unzoomedLeft.width + 0.45) < 0.0001)
        #expect(unzoomedRight.height == 0)
        #expect(unzoomedLeft.height == 0)
        let portrait = ImageViewport.constrainedOffset(CGSize(width: 100, height: 100), zoom: 1,
            imageSize: CGSize(width: 100, height: 400), viewport: CGSize(width: 100, height: 200))
        #expect(portrait.width == 0)
        #expect(portrait.height == 0.5)
    }

    @Test("Image pinch and two-finger pan recognize together without enabling simultaneous browsing")
    func simultaneousImageGestures() {
        let target = TodayGestureTarget(onTap: {}, onDragChanged: { _ in },
                                        onDragEnded: { _, _, _ in }, allowsImageZoom: true)
        let coordinator = target.makeCoordinator()
        let pinch = UIPinchGestureRecognizer()
        let imagePan = UIPanGestureRecognizer()
        imagePan.minimumNumberOfTouches = 2
        let browsingPan = UIPanGestureRecognizer()
        pinch.delegate = coordinator
        imagePan.delegate = coordinator
        browsingPan.delegate = coordinator
        #expect(coordinator.gestureRecognizer(pinch, shouldRecognizeSimultaneouslyWith: imagePan))
        #expect(coordinator.gestureRecognizer(imagePan, shouldRecognizeSimultaneouslyWith: pinch))
        #expect(!coordinator.gestureRecognizer(pinch, shouldRecognizeSimultaneouslyWith: browsingPan))
        #expect(!coordinator.gestureRecognizer(imagePan, shouldRecognizeSimultaneouslyWith: browsingPan))
        #expect(!coordinator.gestureRecognizer(pinch, shouldRecognizeSimultaneouslyWith: UIScrollView().panGestureRecognizer))
        coordinator.target.allowsImageZoom = false
        #expect(!coordinator.gestureRecognizer(pinch, shouldRecognizeSimultaneouslyWith: imagePan))
    }

    @Test("Image gestures attach to the whole scroll viewport and detach cleanly")
    func viewportGestureAttachment() {
        let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        let content = UIView(frame: scroll.bounds)
        let marker = TodayGestureTarget.GestureHostView(frame: CGRect(x: 100, y: 200, width: 120, height: 80))
        let pinch = UIPinchGestureRecognizer()
        let pan = UIPanGestureRecognizer()
        marker.viewportRecognizers = [pinch, pan]
        scroll.addSubview(content)
        content.addSubview(marker)
        marker.installRecognizers()
        #expect(pinch.view === scroll)
        #expect(pan.view === scroll)
        #expect(!marker.point(inside: CGPoint(x: 10, y: 10), with: nil))
        marker.installRecognizers()
        #expect(scroll.gestureRecognizers?.filter { $0 === pinch }.count == 1)
        marker.removeRecognizers()
        #expect(pinch.view == nil)
        #expect(pan.view == nil)
    }

    @Test("Image panning stays within the zoomed viewport and recentres at normal size")
    func imagePanBounds() {
        let offset = CGSize(width: 2, height: -2)
        #expect(ImageViewport.constrainedOffset(offset, zoom: 1) == .zero)
        #expect(ImageViewport.constrainedOffset(offset, zoom: 2) == CGSize(width: 0.5, height: -0.5))
        #expect(ImageViewport.constrainedOffset(offset, zoom: 4) == CGSize(width: 1.5, height: -1.5))
        let smallOffset = CGSize(width: 0.1, height: -0.2)
        #expect(ImageViewport.constrainedOffset(smallOffset, zoom: 2) == smallOffset)
        #expect(ImageViewport.constrainedOffset(smallOffset, zoom: 1.2).height > smallOffset.height)
    }

    @Test("Text outline defaults off and persists per theme without changing dimming")
    func textOutlinePreference() throws {
        let oldChoice = try JSONDecoder().decode(
            ThemeBackgroundChoice.self, from: Data(#"{"usesPhoto":true}"#.utf8)
        )
        #expect(!(oldChoice.outlinesText ?? false))
        let suite = "gayffirmations.outline.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let store = ThemeStore(repository: repository, backgroundRepository: repository)
        try store.setImageDimming(-0.5)
        try store.setOutlinesText(true)
        try store.setUsesImage(false)
        try store.setUsesImage(true)
        #expect(store.backgroundChoice.outlinesText == true)
        #expect(store.backgroundChoice.imageDimming == -0.5)
        try store.select(.steel)
        #expect(!(store.backgroundChoice.outlinesText ?? false))
        try store.select(.eden)
        let restarted = ThemeStore(repository: repository, backgroundRepository: repository)
        #expect(restarted.backgroundChoice.outlinesText == true)
        try restarted.setOutlinesText(false)
        #expect(!(restarted.backgroundChoice.outlinesText ?? false))
        #expect(restarted.backgroundChoice.imageDimming == -0.5)
    }

    @Test("Dimming preserves image defaults and snaps near the default")
    func dimmingRange() {
        #expect(ThemeBackgroundChoice.overlayOpacity(default: 0.48, adjustment: 0) == 0.48)
        #expect(ThemeBackgroundChoice.overlayOpacity(default: 0.48, adjustment: -1) == 0)
        #expect(ThemeBackgroundChoice.overlayOpacity(default: 0.48, adjustment: 1) == 0.85)
        #expect(ThemeBackgroundChoice.snappedDimming(0.04) == 0)
        #expect(ThemeBackgroundChoice.snappedDimming(-0.04) == 0)
        #expect(ThemeBackgroundChoice.snappedDimming(-0.5) == -0.5)
    }

    @Test("Dimming persists per theme and survives toggling images")
    func persistsDimming() throws {
        let suite = "gayffirmations.dimming.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let store = ThemeStore(repository: repository, backgroundRepository: repository)
        try store.setImageDimming(-0.5)
        try store.setUsesImage(false)
        try store.setUsesImage(true)
        #expect(store.backgroundChoice.imageDimming == -0.5)
        try store.select(.steel)
        #expect(store.backgroundChoice.imageDimming == nil)
        try store.select(.eden)
        let restarted = ThemeStore(repository: repository, backgroundRepository: repository)
        #expect(restarted.backgroundChoice.imageDimming == -0.5)
        try restarted.setImageDimming(0)
        #expect(restarted.backgroundChoice.imageDimming == nil)
    }

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
