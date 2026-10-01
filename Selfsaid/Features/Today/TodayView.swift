import SwiftUI

struct TodayView: View {
    let store: AffirmationStore
    let selectionStore: AffirmationSelectionStore
    let scheduleStore: ScheduleStore
    let isUpdating: Bool

    @State private var errorMessage: String?
    @State private var manualSelection: ManualSelection?
    @Environment(\.appTheme) private var appTheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var refreshDate = Date.now

    init(
        store: AffirmationStore,
        selectionStore: AffirmationSelectionStore? = nil,
        scheduleStore: ScheduleStore? = nil,
        isUpdating: Bool = false
    ) {
        self.store = store
        self.selectionStore = selectionStore ?? AffirmationSelectionStore()
        self.scheduleStore = scheduleStore ?? ScheduleStore()
        self.isUpdating = isUpdating
    }

    var body: some View {
        TimelineView(.periodic(from: refreshMinute, by: 60)) { context in
            let affirmation = currentAffirmation(at: context.date)
            let photo = AffirmationPhoto.resolve(
                for: affirmation,
                selectedTags: selectionStore.selection.selectedTags
            )
            GeometryReader { geometry in
                ScrollView {
                    AffirmationMessageLayout(
                        viewportHeight: geometry.size.height,
                        centreFraction: photo?.messagePosition(in: geometry.size) ?? 0.50
                    ) {
                        VStack(spacing: 32) {
                            if let affirmation {
                                if photo == nil {
                                    Image(systemName: appTheme.symbol)
                                        .font(.system(size: 36, weight: .light))
                                        .foregroundStyle(appTheme.accentColor)
                                        .accessibilityHidden(true)
                                }

                                affirmationMessage(affirmation)
                            } else {
                                ContentUnavailableView(
                                    "No Matching Affirmations",
                                    systemImage: "text.quote",
                                    description: Text(selectionStore.selection.emptyMessage)
                                )
                            }
                        }
                        .padding(.horizontal, 28)
                    }
                    .overlay {
                        AffirmationSwipeTarget(
                            onSwipeLeft: { cycleAffirmation(by: 1) },
                            onSwipeRight: { cycleAffirmation(by: -1) }
                        )
                        .accessibilityHidden(true)
                    }
                }
            }
            .foregroundStyle(photo == nil ? Color.primary : Color.white)
            .tint(photo == nil ? appTheme.accentColor : .white)
            .toolbarBackground(photo == nil ? .automatic : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let affirmation {
                        favoriteButton(for: affirmation)
                    }
                }
                .iconOnlyBackground()
            }
            .background {
                if let photo {
                    AffirmationPhotoBackground(photo: photo)
                } else {
                    appTheme.backgroundGradient.ignoresSafeArea()
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshDate = .now }
        }
        .onChange(of: scheduleStore.schedule) { _, _ in
            manualSelection = nil
        }
        .onChange(of: selectionStore.selection) { _, _ in
            manualSelection = nil
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

    private func affirmationMessage(_ affirmation: Affirmation) -> some View {
        Text(affirmation.text)
            .font(appTheme.affirmationFont)
            .lineSpacing(6)
            .frame(maxWidth: 560)
            .multilineTextAlignment(.center)
            .accessibilityLabel("Affirmation: \(affirmation.text)")
            .accessibilityAction(named: "Next affirmation") { cycleAffirmation(by: 1) }
            .accessibilityAction(named: "Previous affirmation") { cycleAffirmation(by: -1) }
    }

    private var refreshMinute: Date {
        Calendar.current.dateInterval(of: .minute, for: refreshDate)?.start ?? refreshDate
    }

    private func currentAffirmation(at date: Date) -> Affirmation? {
        if let manualSelection, date < manualSelection.expiresAt,
           let affirmation = selectedAffirmations.first(where: { $0.id == manualSelection.id }) {
            return affirmation
        }

        return TodayAffirmationResolver().affirmation(
            at: date,
            schedule: scheduleStore.schedule,
            affirmations: selectedAffirmations
        )
    }

    private var selectedAffirmations: [Affirmation] {
        selectionStore.selection.matchingAffirmations(in: store.affirmations)
    }

    private func cycleAffirmation(by offset: Int) {
        let date = Date.now
        let affirmations = selectedAffirmations
        guard affirmations.count > 1,
              let current = currentAffirmation(at: date),
              let index = affirmations.firstIndex(where: { $0.id == current.id }) else { return }

        let nextIndex = (index + offset + affirmations.count) % affirmations.count
        manualSelection = ManualSelection(
            id: affirmations[nextIndex].id,
            expiresAt: TodayAffirmationResolver().nextChange(after: date, schedule: scheduleStore.schedule)
        )
    }

    private struct ManualSelection {
        let id: Affirmation.ID
        let expiresAt: Date
    }

    private func favoriteButton(for affirmation: Affirmation) -> some View {
        Button {
            do {
                try store.toggleFavorite(id: affirmation.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        } label: {
            Image(systemName: affirmation.isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.white)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isUpdating)
        .accessibilityLabel(affirmation.isFavorite ? "Remove from favourites" : "Add to favourites")
    }
}

#Preview("With affirmations") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
}

#Preview("Empty") {
    TodayView(store: AffirmationStore())
}

#Preview("Accessibility text size") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Empty selection at largest text size") {
    TodayView(
        store: AffirmationStore(affirmations: Affirmation.samples),
        selectionStore: AffirmationSelectionStore(selection: .tag("Finding calm during a busy working day"))
    )
    .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Warm Coast — light") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .warm)
        .tint(AppTheme.warm.accentColor)
        .fontDesign(AppTheme.warm.fontDesign)
        .preferredColorScheme(.light)
}

#Preview("Warm Coast — dark") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .warm)
        .tint(AppTheme.warm.accentColor)
        .fontDesign(AppTheme.warm.fontDesign)
        .preferredColorScheme(.dark)
}

#Preview("Midnight — light") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .midnight)
        .tint(AppTheme.midnight.accentColor)
        .fontDesign(AppTheme.midnight.fontDesign)
        .preferredColorScheme(.light)
}

#Preview("Midnight — dark") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .midnight)
        .tint(AppTheme.midnight.accentColor)
        .fontDesign(AppTheme.midnight.fontDesign)
        .preferredColorScheme(.dark)
}

#Preview("Playful Pop — light") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .playful)
        .tint(AppTheme.playful.accentColor)
        .fontDesign(AppTheme.playful.fontDesign)
        .preferredColorScheme(.light)
}

#Preview("Playful Pop — dark") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .playful)
        .tint(AppTheme.playful.accentColor)
        .fontDesign(AppTheme.playful.fontDesign)
        .preferredColorScheme(.dark)
}

#Preview("Quiet Linen — light") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .refined)
        .tint(AppTheme.refined.accentColor)
        .fontDesign(AppTheme.refined.fontDesign)
        .preferredColorScheme(.light)
}

#Preview("Quiet Linen — dark") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .refined)
        .tint(AppTheme.refined.accentColor)
        .fontDesign(AppTheme.refined.fontDesign)
        .preferredColorScheme(.dark)
}

#Preview("Photo — Playful") {
    TodayView(store: AffirmationStore(affirmations: [
        Affirmation(text: "Hey, handsome… looking great!", tags: ["playful"])
    ]))
}

#Preview("Photo — Confidence") {
    TodayView(store: AffirmationStore(affirmations: [
        Affirmation(text: "I can trust myself while I’m still learning.", tags: ["confidence"])
    ]))
}

#Preview("Photo — Self-worth") {
    TodayView(store: AffirmationStore(affirmations: [
        Affirmation(text: "My worth is already here; I don’t have to earn it.", tags: ["self-worth"])
    ]))
}
