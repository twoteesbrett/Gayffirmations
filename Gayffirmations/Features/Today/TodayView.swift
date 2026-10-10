import SwiftUI

struct TodayView: View {
    let store: AffirmationStore
    let fallbackSelectionStore: AffirmationSelectionStore
    let personalizationStore: PersonalizationStore
    let scheduleStore: ScheduleStore
    let isUpdating: Bool
    let themeStore: ThemeStore?
    let sheetDismissalID: UUID?
    let onOpenDestination: (TodayDestination) -> Void

    @State private var controls = TodayControlsState()
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var errorMessage: String?
    @State private var browsingState = TodayBrowsingState()
    @State private var browsingForward = true
    @State private var swipe: SwipePreview?
    @State private var swipeTranslation: CGFloat = 0
    @State private var isSettlingSwipe = false

    private struct SwipePreview {
        let current: Affirmation
        let next: Affirmation
        let browsingState: TodayBrowsingState
        let direction: Int
        let width: CGFloat
        let currentImage: ThemeImage?
        let nextImage: ThemeImage?
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.themeImage) private var themeImage
    @Environment(\.appTheme) private var appTheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var refreshDate = Date.now

    init(
        store: AffirmationStore,
        fallbackSelectionStore: AffirmationSelectionStore? = nil,
        personalizationStore: PersonalizationStore? = nil,
        scheduleStore: ScheduleStore? = nil,
        isUpdating: Bool = false,
        themeStore: ThemeStore? = nil,
        sheetDismissalID: UUID? = nil,
        onOpenDestination: @escaping (TodayDestination) -> Void = { _ in }
    ) {
        self.store = store
        self.fallbackSelectionStore = fallbackSelectionStore ?? AffirmationSelectionStore()
        self.personalizationStore = personalizationStore ?? PersonalizationStore()
        self.scheduleStore = scheduleStore ?? ScheduleStore()
        self.isUpdating = isUpdating
        self.themeStore = themeStore
        self.sheetDismissalID = sheetDismissalID
        self.onOpenDestination = onOpenDestination
    }

    var body: some View {
        TimelineView(.periodic(from: refreshMinute, by: 60)) { context in
            let affirmation = currentAffirmation(at: context.date)
            GeometryReader { geometry in
                // Balance the safe areas to keep the message at the screen's centre.
                let centeringInset = geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
                // The destination has its own viewport, so its text height cannot resize
                // the current page or change the current page's vertical scroll position.
                ScrollView {
                    affirmationPage(
                        swipe?.current ?? affirmation,
                        size: geometry.size, centeringInset: centeringInset
                    )
                    .offset(x: reduceMotion ? 0 : swipeTranslation)
                    .opacity(reduceMotion ? 1 - swipeProgress : 1)
                    .accessibilityHidden(swipe != nil)
                    .overlay {
                        TodayGestureTarget(
                            onTap: { controls.toggle() },
                            onDragChanged: { updateSwipe(translation: $0, width: geometry.size.width) },
                            onDragEnded: { finishSwipe(translation: $0, velocity: $1, cancelled: $2) }
                        )
                        .accessibilityHidden(true)
                    }
                }
                .scrollClipDisabled()
                // A committed destination starts at the top, matching its swipe preview.
                .id((swipe?.current ?? affirmation)?.id)
                .overlay {
                    if let swipe {
                        ScrollView {
                            affirmationPage(
                                swipe.next,
                                size: geometry.size, centeringInset: centeringInset
                            )
                            .foregroundStyle(swipe.nextImage?.textColor ?? appTheme.textColor)
                        }
                        .scrollClipDisabled()
                        .offset(x: reduceMotion ? 0 : swipeTranslation + CGFloat(swipe.direction) * swipe.width)
                        .opacity(reduceMotion ? swipeProgress : 1)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }
                // Keep the resting layout inside the safe area, but let swiping text
                // reach the physical screen edges. Both scroll views use this clip.
                .frame(width: geometry.size.width, height: geometry.size.height)
                .padding(.leading, geometry.safeAreaInsets.leading)
                .padding(.trailing, geometry.safeAreaInsets.trailing)
                .clipped()
                .padding(.leading, -geometry.safeAreaInsets.leading)
                .padding(.trailing, -geometry.safeAreaInsets.trailing)
                .simultaneousGesture(
                    DragGesture().onChanged { _ in controls.registerInteraction() }
                )
            }
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
                themeStore?.updateDisplayedAffirmation(id)
            }
        }
        .foregroundStyle(foregroundColor)
        .tint(foregroundColor)
        .toolbar(.hidden, for: .navigationBar)
        .background {
            ZStack {
                appTheme.backgroundGradient
                if let swipe {
                    GeometryReader { geometry in
                        ZStack {
                            if let image = swipe.currentImage {
                                ImageBackground(image: image)
                                    .offset(x: reduceMotion ? 0 : swipeTranslation / swipe.width * geometry.size.width)
                                    .opacity(reduceMotion ? 1 - swipeProgress : 1)
                            }
                            if let image = swipe.nextImage {
                                ImageBackground(image: image)
                                    .offset(x: reduceMotion ? 0 : (swipeTranslation / swipe.width + CGFloat(swipe.direction)) * geometry.size.width)
                                    .opacity(reduceMotion ? swipeProgress : 1)
                            }
                        }
                        .clipped()
                    }
                    .accessibilityHidden(true)
                } else {
                    TransitioningImageBackground(image: themeImage, browsingForward: browsingForward)
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshDate = .now }
            else { controls.reset() }
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

    private var foregroundColor: Color { themeImage?.textColor ?? appTheme.textColor }

    private var emptyState: some View {
        let libraryIsEmpty = store.affirmations.isEmpty
        let needsName = !fallbackSelectionStore.selection.matchingAffirmations(in: store.affirmations).isEmpty
        return ContentUnavailableView {
            Label(libraryIsEmpty ? "No Affirmations" : (needsName ? "Add a Name" : "No Matching Affirmations"), systemImage: "text.quote")
                .foregroundStyle(foregroundColor)
        } description: {
            Text(libraryIsEmpty
                 ? "Tap the screen, then open Library in the top-left corner to add your first affirmation."
                 : (needsName
                    ? "Add a name in Settings to use these personalised affirmations."
                    : "Choose different fallback content in Schedules or add matching affirmations in Library."))
                .foregroundStyle(foregroundColor.opacity(0.85))
        }
    }

    private func affirmationPage(
        _ affirmation: Affirmation?, size: CGSize, centeringInset: CGFloat
    ) -> some View {
        ZStack {
            if let affirmation {
                affirmationMessage(affirmation)
                    .id(affirmation.id)
                    .transition(browsingTransition(width: size.width))
            } else {
                emptyState
            }
        }
        // Reserve room for the controls even while hidden, so text never jumps.
        .padding(.horizontal, 28)
        .padding(.top, 68 + max(0, -centeringInset))
        .padding(.bottom, 68 + max(0, centeringInset))
        .frame(maxWidth: .infinity, minHeight: size.height)
    }

    private func affirmationMessage(_ affirmation: Affirmation) -> some View {
        Text(affirmation.text)
            .affirmationTypography(appTheme)
            .lineSpacing(appTheme.affirmationLineSpacing)
            .frame(maxWidth: 560)
            .multilineTextAlignment(.center)
            .accessibilityLabel("Affirmation: \(affirmation.text)")
            .accessibilityAction(named: "Next affirmation") { cycleAffirmation(by: 1) }
            .accessibilityAction(named: "Previous affirmation") { cycleAffirmation(by: -1) }
    }

    private func browsingTransition(width: CGFloat) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let distance = browsingForward ? width : -width
        return .asymmetric(
            insertion: .offset(x: distance),
            removal: .offset(x: -distance)
        )
    }

    private var refreshMinute: Date {
        Calendar.current.dateInterval(of: .minute, for: refreshDate)?.start ?? refreshDate
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

    private var swipeProgress: Double {
        guard let swipe else { return 0 }
        return Double(min(1, abs(swipeTranslation) / swipe.width))
    }

    private func updateSwipe(translation: CGFloat, width: CGFloat) {
        guard !isSettlingSwipe, width > 0 else { return }
        controls.registerInteraction()
        let direction = translation <= 0 ? 1 : -1
        if swipe?.direction != direction {
            let now = Date.now
            let context = context(at: now)
            var previewState = browsingState
            guard let current = browsingState.affirmation(at: now, context: context),
                  let next = previewState.cycle(by: direction, at: now, context: context) else { return }
            swipe = SwipePreview(
                current: current, next: next, browsingState: previewState,
                direction: direction, width: width, currentImage: themeImage,
                nextImage: themeStore?.image(for: next.id, direction: direction) ?? themeImage
            )
        }
        swipeTranslation = max(-width, min(width, translation))
    }

    private func finishSwipe(translation: CGFloat, velocity: CGFloat, cancelled: Bool) {
        guard let preview = swipe, !isSettlingSwipe else { return }
        controls.registerInteraction()
        isSettlingSwipe = true
        // Project a short distance ahead so a quick flick can complete a small drag.
        let projectedDistance = -(translation + velocity * 0.18) * CGFloat(preview.direction)
        let commits = !cancelled && projectedDistance > preview.width * 0.3
        let destination = commits ? -CGFloat(preview.direction) * preview.width : 0
        withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.25), completionCriteria: .removed) {
            swipeTranslation = destination
        } completion: {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                // A reminder may have changed the selection while the finger was held.
                if commits, currentAffirmation(at: .now)?.id == preview.current.id {
                    browsingForward = preview.direction > 0
                    themeStore?.updateDisplayedAffirmation(preview.next.id, direction: preview.direction)
                    browsingState = preview.browsingState
                }
                swipe = nil
                swipeTranslation = 0
                isSettlingSwipe = false
            }
        }
    }

    private func cycleAffirmation(by offset: Int) {
        guard swipe == nil else { return }
        controls.registerInteraction()
        var updatedBrowsingState = browsingState
        let now = Date.now
        guard let next = updatedBrowsingState.cycle(
            by: offset, at: now, context: context(at: now)
        ) else { return }

        browsingForward = offset > 0
        withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.30)) {
            themeStore?.updateDisplayedAffirmation(next.id, direction: offset)
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

#if DEBUG
#Preview("Eden") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .themeAppearance(.eden)
}

#Preview("Steel") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .themeAppearance(.steel)
}

#Preview("Disco") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .themeAppearance(.disco)
}

#Preview("Empty") {
    TodayView(store: AffirmationStore())
}

#Preview("Accessibility text size") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Empty selection at largest text size") {
    TodayView(
        store: AffirmationStore(affirmations: PreviewContent.affirmations),
        fallbackSelectionStore: AffirmationSelectionStore(selection: .tag("Finding calm during a busy working day"))
    )
    .environment(\.dynamicTypeSize, .accessibility5)
}
#endif

#if DEBUG
#Preview("Steel · Strength") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .themeAppearance(.steel)
        .environment(\.themeImage, AppTheme.steel.images[0])
}
#Preview("Steel · Release") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .themeAppearance(.steel)
        .environment(\.themeImage, AppTheme.steel.images[1])
}
#endif
