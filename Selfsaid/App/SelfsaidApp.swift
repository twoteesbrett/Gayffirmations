//
//  SelfsaidApp.swift
//  Selfsaid
//
//  Created by Brett Fisher on 28/09/2026.
//

import SwiftUI

@main
struct SelfsaidApp: App {
    @State private var affirmationStore: AffirmationStore
    @State private var scheduleStore: ScheduleStore
    @State private var themeStore: ThemeStore
    private let notificationCoordinator: NotificationCoordinator
    private let resetCoordinator: AppDataResetCoordinator

    init() {
        let repository = UserDefaultsRepository()
        let affirmationStore = AffirmationStore(
            repository: repository,
            defaultAffirmations: Affirmation.samples
        )
        let scheduleStore = ScheduleStore(
            repository: repository,
            defaultSchedule: AffirmationSchedule()
        )
        let themeStore = ThemeStore(
            repository: repository,
            defaultTheme: .warm
        )

        _affirmationStore = State(initialValue: affirmationStore)
        _scheduleStore = State(initialValue: scheduleStore)
        _themeStore = State(initialValue: themeStore)
        let notificationCoordinator = NotificationCoordinator(
            affirmationStore: affirmationStore,
            scheduleStore: scheduleStore,
            scheduler: LocalNotificationService(),
            selectionStore: AffirmationSelectionStore(repository: repository)
        )
        self.notificationCoordinator = notificationCoordinator
        resetCoordinator = AppDataResetCoordinator(
            affirmationStore: affirmationStore,
            scheduleStore: scheduleStore,
            themeStore: themeStore,
            notificationCoordinator: notificationCoordinator,
            repository: repository
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                affirmationStore: affirmationStore,
                scheduleStore: scheduleStore,
                themeStore: themeStore,
                notificationCoordinator: notificationCoordinator,
                resetCoordinator: resetCoordinator
            )
            .environment(\.appTheme, themeStore.selectedTheme)
            .tint(themeStore.selectedTheme.accentColor)
            .fontDesign(themeStore.selectedTheme.fontDesign)
        }
    }
}
