//
//  ContentView.swift
//  Gayffirmations
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

    @State private var startupPersistenceErrorMessage: String?
    @State private var destination: Destination?

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
        NavigationStack {
            TodayView(
                store: affirmationStore,
                selectionStore: notificationCoordinator.selectionStore,
                scheduleStore: scheduleStore,
                isUpdating: notificationCoordinator.isUpdating
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Library", systemImage: "books.vertical") { destination = .library }
                        Button("Settings", systemImage: "gearshape") { destination = .settings }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(.white)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Menu")
                }
                .iconOnlyBackground()
            }
            .sheet(item: $destination) { destination in
                destinationView(destination)
            }
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
                "Gayffirmations is showing default data and will not save changes "
                    + "to the affected section during this session. Your existing "
                    + "saved data has not been overwritten.\n\n"
                    + (startupPersistenceErrorMessage ?? "")
            )
        }
    }

    @ViewBuilder
    private func destinationView(_ destination: Destination) -> some View {
        switch destination {
        case .library:
            LibraryView(store: affirmationStore, notificationCoordinator: notificationCoordinator)
        case .settings:
            SettingsView(
                affirmationStore: affirmationStore,
                scheduleStore: scheduleStore,
                themeStore: themeStore,
                notificationCoordinator: notificationCoordinator,
                resetCoordinator: resetCoordinator
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

private enum Destination: Identifiable {
    case library, settings
    var id: Self { self }
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
            userDefaults: UserDefaults(suiteName: "gayffirmations.previews")!
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
