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

    @State private var startupPersistenceErrorMessage: String?

    init(
        affirmationStore: AffirmationStore,
        scheduleStore: ScheduleStore,
        themeStore: ThemeStore,
        notificationCoordinator: NotificationCoordinator
    ) {
        self.affirmationStore = affirmationStore
        self.scheduleStore = scheduleStore
        self.themeStore = themeStore
        self.notificationCoordinator = notificationCoordinator

        let failures = [
            affirmationStore.persistenceErrorMessage.map {
                "Affirmations: \($0)"
            },
            scheduleStore.persistenceErrorMessage.map {
                "Schedule: \($0)"
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
        TabView {
            TodayView(store: affirmationStore)
                .floatingTabBarClearance()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            LibraryView(store: affirmationStore)
                .floatingTabBarClearance()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

            SettingsView(
                affirmationStore: affirmationStore,
                scheduleStore: scheduleStore,
                themeStore: themeStore,
                notificationCoordinator: notificationCoordinator
            )
                .floatingTabBarClearance()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
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

    ContentView(
        affirmationStore: affirmationStore,
        scheduleStore: scheduleStore,
        themeStore: ThemeStore(),
        notificationCoordinator: NotificationCoordinator(
            affirmationStore: affirmationStore,
            scheduleStore: scheduleStore,
            scheduler: LocalNotificationService()
        )
    )
}
