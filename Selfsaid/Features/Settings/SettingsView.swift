import SwiftUI

struct SettingsView: View {
    let affirmationStore: AffirmationStore
    let scheduleStore: ScheduleStore
    let themeStore: ThemeStore
    let notificationCoordinator: NotificationCoordinator
    let resetCoordinator: AppDataResetCoordinator

    @State private var pendingReset: ResetAction?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    NavigationLink {
                        ThemePickerView(store: themeStore)
                    } label: {
                        LabeledContent("Theme", value: themeStore.selectedTheme.name)
                    }
                }

                Section("Notifications") {
                    NavigationLink {
                        ScheduleView(
                            store: scheduleStore,
                            notificationCoordinator: notificationCoordinator
                        )
                    } label: {
                        LabeledContent("Daily reminders") {
                            Text(scheduleStore.schedule.isEnabled ? "On" : "Off")
                        }
                    }
                }

                Section("Data") {
                    resetButton(.affirmations)
                    resetButton(.schedule)
                    resetButton(.all)
                }
            }
            .disabled(notificationCoordinator.isUpdating)
            .navigationTitle("Settings")
            .confirmationDialog(
                pendingReset?.title ?? "Reset",
                isPresented: resetConfirmationIsPresented,
                titleVisibility: .visible
            ) {
                if let pendingReset {
                    Button(pendingReset.confirmationLabel, role: .destructive) {
                        perform(pendingReset)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let pendingReset {
                    Text(pendingReset.message)
                }
            }
            .alert("Unable to Reset", isPresented: errorIsPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "The selected data could not be reset.")
            }
        }
    }

    private var resetConfirmationIsPresented: Binding<Bool> {
        Binding(
            get: { pendingReset != nil },
            set: { if !$0 { pendingReset = nil } }
        )
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func resetButton(_ action: ResetAction) -> some View {
        Button(action.label, role: action == .all ? .destructive : nil) {
            pendingReset = action
        }
    }

    private func perform(_ action: ResetAction) {
        pendingReset = nil

        do {
            switch action {
            case .affirmations:
                try affirmationStore.restoreDefaults()
            case .schedule:
                try notificationCoordinator.resetSchedule()
            case .all:
                try resetCoordinator.resetAll()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum ResetAction: String, Identifiable {
    case affirmations
    case schedule
    case all

    var id: Self { self }

    var label: String {
        switch self {
        case .affirmations:
            "Restore Default Affirmations"
        case .schedule:
            "Reset Notification Schedule"
        case .all:
            "Reset All App Data"
        }
    }

    var title: String {
        switch self {
        case .affirmations:
            "Restore Default Affirmations?"
        case .schedule:
            "Reset Notification Schedule?"
        case .all:
            "Reset All App Data?"
        }
    }

    var confirmationLabel: String {
        switch self {
        case .affirmations:
            "Restore Affirmations"
        case .schedule:
            "Reset Schedule"
        case .all:
            "Reset Everything"
        }
    }

    var message: String {
        switch self {
        case .affirmations:
            "This replaces your affirmation library, including custom affirmations and favorites, with the original defaults."
        case .schedule:
            "This turns off daily reminders, restores the default times, and removes pending notifications."
        case .all:
            "This restores the affirmation library, notification schedule, and theme to their defaults. Custom affirmations and favorites will be removed, and pending notifications will be cancelled."
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
        scheduler: LocalNotificationService()
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

    SettingsView(
        affirmationStore: affirmationStore,
        scheduleStore: scheduleStore,
        themeStore: themeStore,
        notificationCoordinator: notificationCoordinator,
        resetCoordinator: resetCoordinator
    )
}
