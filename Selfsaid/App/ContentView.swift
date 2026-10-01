//
//  ContentView.swift
//  Selfsaid
//
//  Created by Brett Fisher on 28/09/2026.
//

import SwiftUI

struct ContentView: View {
    let affirmationStore: AffirmationStore
    let scheduleStore: ScheduleStore
    let themeStore: ThemeStore
    let notificationCoordinator: NotificationCoordinator
    let resetCoordinator: AppDataResetCoordinator

    @State private var selectedTab: AppTab = .today
    @State private var startupPersistenceErrorMessage: String?

    init(
        affirmationStore: AffirmationStore,
        scheduleStore: ScheduleStore,
        themeStore: ThemeStore,
        notificationCoordinator: NotificationCoordinator,
        resetCoordinator: AppDataResetCoordinator
    ) {
        self.affirmationStore = affirmationStore
        self.scheduleStore = scheduleStore
        self.themeStore = themeStore
        self.notificationCoordinator = notificationCoordinator
        self.resetCoordinator = resetCoordinator

        let failures = [
            affirmationStore.persistenceErrorMessage.map {
                "Affirmations: \($0)"
            },
            scheduleStore.persistenceErrorMessage.map {
                "Schedule: \($0)"
            },
            notificationCoordinator.selectionStore.persistenceErrorMessage.map {
                "Affirmation selection: \($0)"
            },
            themeStore.persistenceErrorMessage.map {
                "Theme: \($0)"
            }
        ].compactMap { $0 }

        _startupPersistenceErrorMessage = State(
            initialValue: failures.isEmpty
                ? nil
                : failures.joined(separator: "\n\n")
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(store: affirmationStore, selectionStore: notificationCoordinator.selectionStore)
                .floatingTabBarClearance()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
                .tag(AppTab.today)

            LibraryView(store: affirmationStore, notificationCoordinator: notificationCoordinator)
                .floatingTabBarClearance()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(AppTab.library)

            SettingsView(
                affirmationStore: affirmationStore,
                scheduleStore: scheduleStore,
                themeStore: themeStore,
                notificationCoordinator: notificationCoordinator,
                resetCoordinator: resetCoordinator,
                showLibrary: { selectedTab = .library }
            )
                .floatingTabBarClearance()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .task {
            await notificationCoordinator.reconcileOnLaunch()
        }
        .alert("Unable to Update Reminders", isPresented: Binding(
            get: { notificationCoordinator.errorMessage != nil },
            set: { if !$0 { notificationCoordinator.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(notificationCoordinator.errorMessage ?? "Please try again.")
        }
        .alert(
            "Unable to Load Saved Data",
            isPresented: startupPersistenceErrorIsPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "Selfsaid is showing default data and will not save changes "
                    + "to the affected section during this session. Your existing "
                    + "saved data has not been overwritten.\n\n"
                    + (startupPersistenceErrorMessage ?? "")
            )
        }
    }

    private var startupPersistenceErrorIsPresented: Binding<Bool> {
        Binding(
            get: { startupPersistenceErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    startupPersistenceErrorMessage = nil
                }
            }
        )
    }
}

private enum AppTab: Hashable {
    case today, library, settings
}

private extension View {
    @ViewBuilder
    func floatingTabBarClearance() -> some View {
        if #available(iOS 26.0, *) {
            safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: 72)
                    .accessibilityHidden(true)
            }
        } else {
            self
        }
    }
}

#Preview {
    let affirmationStore = AffirmationStore(affirmations: Affirmation.samples)
    let scheduleStore = ScheduleStore()
    let themeStore = ThemeStore()
    let notificationCoordinator = NotificationCoordinator(
        affirmationStore: affirmationStore,
        scheduleStore: scheduleStore,
        scheduler: PreviewNotificationScheduler()
    )
    let resetCoordinator = AppDataResetCoordinator(
        affirmationStore: affirmationStore,
        scheduleStore: scheduleStore,
        themeStore: themeStore,
        notificationCoordinator: notificationCoordinator,
        repository: UserDefaultsRepository(
            userDefaults: UserDefaults(suiteName: "Selfsaid.previews")!
        )
    )

    ContentView(
        affirmationStore: affirmationStore,
        scheduleStore: scheduleStore,
        themeStore: themeStore,
        notificationCoordinator: notificationCoordinator,
        resetCoordinator: resetCoordinator
    )
}
