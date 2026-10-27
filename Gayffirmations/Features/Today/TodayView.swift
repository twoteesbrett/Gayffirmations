import SwiftUI
import UIKit

/// Resolve content at the data boundary, outside gesture-driven view updates.
struct TodayView: View {
    let date: Date
    let store: AffirmationStore
    let fallbackSelectionStore: AffirmationSelectionStore
    let personalizationStore: PersonalizationStore
    let scheduleStore: ScheduleStore
    let isUpdating: Bool
    let themeStore: ThemeStore?
    let sheetDismissalID: UUID?
    let onOpenDestination: (TodayDestination) -> Void

    let resolvedContext: TodayAffirmationContext?

    init(
        store: AffirmationStore,
        date: Date = .now,
        context: TodayAffirmationContext? = nil,
        fallbackSelectionStore: AffirmationSelectionStore? = nil,
        personalizationStore: PersonalizationStore? = nil,
        scheduleStore: ScheduleStore? = nil,
        isUpdating: Bool = false,
        themeStore: ThemeStore? = nil,
        sheetDismissalID: UUID? = nil,
        onOpenDestination: @escaping (TodayDestination) -> Void = { _ in }
    ) {
        self.date = date
        self.resolvedContext = context
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
        let context = resolvedContext ?? TodayAffirmationResolver().context(
            at: date, schedules: scheduleStore.schedules, affirmations: store.affirmations,
            fallbackSelection: fallbackSelectionStore.selection, name: personalizationStore.name
        )
        TodayInteractionView(
            date: date, store: store, fallbackSelectionStore: fallbackSelectionStore,
            personalizationStore: personalizationStore, scheduleStore: scheduleStore,
            isUpdating: isUpdating, themeStore: themeStore, sheetDismissalID: sheetDismissalID,
            onOpenDestination: onOpenDestination, resolvedContext: context
        )
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
