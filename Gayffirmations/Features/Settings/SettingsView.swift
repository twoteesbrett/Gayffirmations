import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let affirmationStore: AffirmationStore
    let scheduleStore: ScheduleStore
    let notificationCoordinator: NotificationCoordinator
    let resetCoordinator: AppDataResetCoordinator

    @State private var isEditingName = false
    @State private var isShowingSchedule = false
    @State private var pendingReset: ResetAction?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Personalisation") {
                    Button {
                        isEditingName = true
                    } label: {
                        disclosureLabel("Name", value: notificationCoordinator.personalizationStore.name.isEmpty
                                        ? "Not set" : notificationCoordinator.personalizationStore.name)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Edit the name used in personalised affirmations")
                }
                Section("Notifications") {
                    Button {
                        isShowingSchedule = true
                    } label: {
                        disclosureLabel("Daily reminders", value: notificationCoordinator.deliveryIsPaused
                                        ? "Paused" : (scheduleStore.schedule.isEnabled ? "On" : "Off"))
                    }
                    .buttonStyle(.plain)
                }

                Section("Data") {
                    resetButton(.affirmations)
                    resetButton(.schedule)
                    resetButton(.all)
                }
            }
            .themedBackground()
            .disabled(notificationCoordinator.isUpdating)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $isShowingSchedule) {
                ScheduleView(
                    store: scheduleStore,
                    notificationCoordinator: notificationCoordinator
                )
            }
            .sheet(isPresented: $isEditingName) {
                NameEditorView(notificationCoordinator: notificationCoordinator)
            }
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
            .alert("Unable to Save Settings", isPresented: errorIsPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Your settings could not be saved.")
            }
        }
    }

    private func disclosureLabel(_ title: String, value: String) -> some View {
        HStack(spacing: 12) {
            LabeledContent(title, value: value)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.trailing, 2)
        .contentShape(Rectangle())
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

private enum ResetAction {
    case affirmations
    case schedule
    case all

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
            "This restores the affirmation library, notification schedule, affirmation selection, name, and theme to their defaults. Custom affirmations and favorites will be removed, and pending notifications will be cancelled."
        }
    }
}

#if DEBUG
#Preview {
    let affirmationStore = AffirmationStore(affirmations: PreviewContent.affirmations)
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

    SettingsView(
        affirmationStore: affirmationStore,
        scheduleStore: scheduleStore,
        notificationCoordinator: notificationCoordinator,
        resetCoordinator: resetCoordinator
    )
}
#endif
