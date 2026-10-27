import SwiftUI
import UIKit

struct TodayInteractionView: View {
    let date: Date
    let store: AffirmationStore
    let fallbackSelectionStore: AffirmationSelectionStore
    let personalizationStore: PersonalizationStore
    let scheduleStore: ScheduleStore
    let isUpdating: Bool
    let themeStore: ThemeStore?
    let sheetDismissalID: UUID?
    let onOpenDestination: (TodayDestination) -> Void

    let resolvedContext: TodayAffirmationContext

    @State private var controls = TodayControlsState()
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var errorMessage: String?
    @State private var browsingState = TodayBrowsingState()
    @State private var browsingForward = true
    @State private var swipeState = TodaySwipeState()
    @State private var imageInteraction = TodayImageInteractionState()
    @State private var imageViewportSize: CGSize = .zero

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.themeImage) private var themeImage
    @Environment(\.appTheme) private var appTheme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let affirmation = browsingState.affirmation(at: date, context: resolvedContext)
        TodaySwipePresentation(
            affirmation: affirmation, swipeState: swipeState,
            preventsTextScrolling: themeImage != nil && imageInteraction.preventsTextScrolling,
            onInteraction: { controls.registerInteraction() },
            page: { affirmation, size, inset in
                affirmationPage(affirmation, size: size, centeringInset: inset)
            },
            gesture: gestureTarget
        )
        .overlay {
            TodayCornerControls(
                affirmation: affirmation,
                isUpdating: isUpdating,
                onOpenDestination: openDestination,
                onToggleFavorite: {
                    if let affirmation { toggleFavorite(affirmation) }
                }
            )
            .opacity(controls.isVisible ? 1 : 0)
            .allowsHitTesting(controls.isVisible)
            .accessibilityHidden(!controls.isVisible)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: controls.isVisible)
        }
        .onChange(of: affirmation?.id, initial: true) { _, id in
            themeStore?.updateDisplayedAffirmation(id, theme: appTheme)
        }
        .foregroundStyle(foregroundColor)
        .tint(foregroundColor)
        .toolbar(.hidden, for: .navigationBar)
        .background {
            TodayBackground(swipeState: swipeState, imageInteraction: imageInteraction,
                            browsingForward: browsingForward)
            .ignoresSafeArea()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                imageViewportSize = size
                updateImageGeometry()
            }
        }
        .onChange(of: themeImage?.id, initial: true) { _, _ in
            imageInteraction.reset()
            updateImageGeometry()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { controls.reset() }
        }
        .onChange(of: voiceOverEnabled, initial: true) { _, enabled in
            controls.setAlwaysVisible(enabled)
        }
        .onChange(of: sheetDismissalID) { _, _ in
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                controls.show()
            }
        }
        .task(id: controls.hideDeadline) {
            guard let deadline = controls.hideDeadline else { return }
            do {
                try await Task.sleep(for: .seconds(max(0, deadline.timeIntervalSinceNow)))
                try Task.checkCancellation()
                controls.expire(deadline: deadline)
            } catch is CancellationError {
                // A new interaction or disappearing view cancels the previous timeout.
            } catch {
                controls.reset()
            }
        }
        .onChange(of: scheduleStore.schedules) { _, _ in
            browsingState.reset()
        }
        .onChange(of: fallbackSelectionStore.selection) { _, _ in
            browsingState.reset()
        }
        .alert("Unable to Save Favourite", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func gestureTarget(width: CGFloat) -> some View {
        TodayGestureTarget(
            onTap: { controls.toggle() },
            onDragChanged: { updateSwipe(translation: $0, width: width) },
            onDragEnded: { finishSwipe(translation: $0, velocity: $1, cancelled: $2) },
            allowsImageZoom: themeImage != nil && swipeState.preview == nil,
            onPinch: { scale, ended in
                controls.registerInteraction()
                imageInteraction.pinch(scale: scale, ended: ended)
            },
            pansImage: themeImage != nil && imageInteraction.zoom > 1,
            onImagePan: { translation, ended in
                controls.registerInteraction()
                imageInteraction.pan(translation: translation, ended: ended)
            }
        )
    }

    private var foregroundColor: Color { themeImage?.textColor ?? appTheme.textColor }

    private func updateImageGeometry() {
        let imageSize = themeImage.flatMap { UIImage(named: $0.id)?.size } ?? .zero
        imageInteraction.updateGeometry(viewport: imageViewportSize, imageSize: imageSize,
                                        focalPoint: themeImage?.focalPoint ?? .center)
    }

    private var emptyState: some View {
        let libraryIsEmpty = store.affirmations.isEmpty
        let needsName = personalizationStore.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && fallbackSelectionStore.selection.matchingAffirmations(in: store.affirmations)
                .contains { $0.usesName && MessageMarkup($0.text).hasVisibleText }
        return ContentUnavailableView {
            Label(libraryIsEmpty ? "No Affirmations" : (needsName ? "Add a Name" : "No Matching Affirmations"), systemImage: "text.quote")
                .foregroundStyle(foregroundColor)
        } description: {
            Text(libraryIsEmpty
                 ? "Tap the screen, then open Library in the top-left corner to add your first affirmation."
                 : (needsName
                    ? "Add a name in Settings to use these personalised affirmations."
                    : "Choose different affirmations under Today in Settings or add matching affirmations in Library."))
                .foregroundStyle(foregroundColor.opacity(0.85))
        }
    }

    private func affirmationPage(
        _ affirmation: Affirmation?, size: CGSize, centeringInset: CGFloat
    ) -> some View {
        TodayAffirmationPage(
            affirmation: affirmation, size: size, centeringInset: centeringInset,
            browsingForward: browsingForward,
            outlinesText: themeImage != nil && (themeStore?.backgroundChoice(for: appTheme).outlinesText ?? false),
            onCycle: cycleAffirmation,
            emptyContent: { emptyState }
        )
    }

    private func currentAffirmation(at date: Date) -> Affirmation? {
        browsingState.affirmation(at: date, context: context(at: date))
    }

    private func context(at date: Date) -> TodayAffirmationContext {
        TodayAffirmationResolver().context(
            at: date, schedules: scheduleStore.schedules, affirmations: store.affirmations,
            fallbackSelection: fallbackSelectionStore.selection, name: personalizationStore.name
        )
    }

    private func updateSwipe(translation: CGFloat, width: CGFloat) {
        guard !swipeState.isSettling, width > 0 else { return }
        controls.registerInteraction()
        let direction = translation <= 0 ? 1 : -1
        if swipeState.preview?.direction != direction {
            let now = Date.now
            let context = context(at: now)
            var previewState = browsingState
            guard let current = browsingState.affirmation(at: now, context: context),
                  let next = previewState.cycle(by: direction, at: now, context: context) else { return }
            swipeState.preview = TodaySwipeState.Preview(
                current: current, next: next, browsingState: previewState,
                direction: direction, width: width, currentImage: themeImage,
                nextImage: themeStore?.image(for: next.id, direction: direction, theme: appTheme) ?? themeImage
            )
        }
        swipeState.translation = max(-width, min(width, translation))
    }

    private func finishSwipe(translation: CGFloat, velocity: CGFloat, cancelled: Bool) {
        guard let preview = swipeState.preview, !swipeState.isSettling else { return }
        controls.registerInteraction()
        swipeState.isSettling = true
        let commits = swipeState.shouldCommit(translation: translation, velocity: velocity, cancelled: cancelled)
        let destination = commits ? -CGFloat(preview.direction) * preview.width : 0
        withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.25), completionCriteria: .removed) {
            swipeState.translation = destination
        } completion: {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                // A reminder may have changed the selection while the finger was held.
                if commits, currentAffirmation(at: .now)?.id == preview.current.id {
                    browsingForward = preview.direction > 0
                    themeStore?.updateDisplayedAffirmation(preview.next.id, direction: preview.direction, theme: appTheme)
                    browsingState = preview.browsingState
                }
                swipeState.reset()
            }
        }
    }

    private func cycleAffirmation(by offset: Int) {
        guard swipeState.preview == nil else { return }
        controls.registerInteraction()
        var updatedBrowsingState = browsingState
        let now = Date.now
        guard let next = updatedBrowsingState.cycle(
            by: offset, at: now, context: context(at: now)
        ) else { return }

        browsingForward = offset > 0
        withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.30)) {
            themeStore?.updateDisplayedAffirmation(next.id, direction: offset, theme: appTheme)
            browsingState = updatedBrowsingState
        }
    }

    private func openDestination(_ destination: TodayDestination) {
        controls.reset()
        onOpenDestination(destination)
    }

    private func toggleFavorite(_ affirmation: Affirmation) {
        controls.registerInteraction()
        do {
            try store.toggleFavorite(id: affirmation.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
