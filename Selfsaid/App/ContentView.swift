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
    let notificationCoordinator: NotificationCoordinator

    @State private var startupPersistenceErrorMessage: String?

    init(
        affirmationStore: AffirmationStore,
        scheduleStore: ScheduleStore,
        notificationCoordinator: NotificationCoordinator
    ) {
        self.affirmationStore = affirmationStore
        self.scheduleStore = scheduleStore
        self.notificationCoordinator = notificationCoordinator

        let failures = [
            affirmationStore.persistenceErrorMessage.map {
                "Affirmations: \($0)"
            },
            scheduleStore.persistenceErrorMessage.map {
                "Schedule: \($0)"
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
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            LibraryView(store: affirmationStore)
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

            ScheduleView(
                store: scheduleStore,
                notificationCoordinator: notificationCoordinator
            )
                .tabItem {
                    Label("Schedule", systemImage: "clock")
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

#Preview {
    let affirmationStore = AffirmationStore(affirmations: Affirmation.samples)
    let scheduleStore = ScheduleStore()

    ContentView(
        affirmationStore: affirmationStore,
        scheduleStore: scheduleStore,
        notificationCoordinator: NotificationCoordinator(
            affirmationStore: affirmationStore,
            scheduleStore: scheduleStore,
            scheduler: LocalNotificationService()
        )
    )
}
