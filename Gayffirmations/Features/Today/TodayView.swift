import SwiftUI

struct TodayView: View {
    let store: AffirmationStore
    let selectionStore: AffirmationSelectionStore
    let scheduleStore: ScheduleStore
    let isUpdating: Bool

    @State private var errorMessage: String?
    @State private var manualSelection: ManualSelection?
    @State private var browsingForward = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            GeometryReader { geometry in
                // Balance the space reserved for the toolbar and home indicator so
                // the message sits at the screen's centre, rather than below it.
                let centeringInset = geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
                ScrollView {
                    ZStack {
                        if let affirmation {
                            affirmationMessage(affirmation)
                                .id(affirmation.id)
                                .transition(messageTransition(width: geometry.size.width))
                        } else {
                            ContentUnavailableView {
                                Label("No Matching Affirmations", systemImage: "text.quote")
                                    .foregroundStyle(appTheme.textColor)
                            } description: {
                                Text(selectionStore.selection.emptyMessage)
                                    .foregroundStyle(appTheme.textColor.opacity(0.85))
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 24 + max(0, -centeringInset))
                    .padding(.bottom, 24 + max(0, centeringInset))
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    .overlay {
                        AffirmationSwipeTarget(
                            onSwipeLeft: { cycleAffirmation(by: 1) },
                            onSwipeRight: { cycleAffirmation(by: -1) }
                        )
                        .accessibilityHidden(true)
                    }
                }
                .clipped()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let affirmation {
                        favoriteButton(for: affirmation)
                            .transaction { $0.animation = nil }
                    }
                }
                .iconOnlyBackground()
            }
        }
        .foregroundStyle(appTheme.textColor)
        .tint(appTheme.textColor)
        .toolbarBackground(.hidden, for: .navigationBar)
        .background {
            appTheme.backgroundGradient.ignoresSafeArea()
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

    private func messageTransition(width: CGFloat) -> AnyTransition {
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
        browsingForward = offset > 0
        withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.30)) {
            manualSelection = ManualSelection(
                id: affirmations[nextIndex].id,
                expiresAt: TodayAffirmationResolver().nextChange(after: date, schedule: scheduleStore.schedule)
            )
        }
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
                .foregroundStyle(appTheme.textColor)
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
