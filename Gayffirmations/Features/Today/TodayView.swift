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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.themePhoto) private var themePhoto
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
                ScrollView {
                    ZStack {
                        if let affirmation {
                            affirmationMessage(affirmation)
                                .id(affirmation.id)
                                .transition(browsingTransition(width: geometry.size.width))
                        } else {
                            emptyState
                        }
                    }
                    // Reserve room for the controls even while hidden, so text never jumps.
                    .padding(.horizontal, 28)
                    .padding(.top, 68 + max(0, -centeringInset))
                    .padding(.bottom, 68 + max(0, centeringInset))
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    .overlay {
                        TodayGestureTarget(
                            onTap: { controls.toggle() },
                            onSwipeLeft: { cycleAffirmation(by: 1) },
                            onSwipeRight: { cycleAffirmation(by: -1) }
                        )
                        .accessibilityHidden(true)
                    }
                }
                .clipped()
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
                TransitioningPhotoBackground(photo: themePhoto, browsingForward: browsingForward)
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
            controls.show()
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

    private var foregroundColor: Color { themePhoto?.textColor ?? appTheme.textColor }

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

    private func affirmationMessage(_ affirmation: Affirmation) -> some View {
        Text(affirmation.text)
            .font(appTheme.affirmationFont)
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

    private func cycleAffirmation(by offset: Int) {
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
#Preview("Nature") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .themeAppearance(.nature)
}

#Preview("Steel") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .themeAppearance(.steel)
}

#Preview("Refined") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .themeAppearance(.refined)
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
        .environment(\.themePhoto, AppTheme.steel.photos[0])
}
#Preview("Steel · Release") {
    TodayView(store: AffirmationStore(affirmations: PreviewContent.affirmations))
        .themeAppearance(.steel)
        .environment(\.themePhoto, AppTheme.steel.photos[1])
}
#endif
