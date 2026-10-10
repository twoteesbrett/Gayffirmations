import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let affirmationStore: AffirmationStore
    let scheduleStore: ScheduleStore
    let notificationCoordinator: NotificationCoordinator
    let resetCoordinator: AppDataResetCoordinator

    @State private var isEditingName = false
    @State private var isShowingSchedule = false
    @State private var isShowingSound = false
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
                        disclosureLabel("Schedules", value: notificationCoordinator.deliverySummary)
                    }
                    .buttonStyle(.plain)
                    Button {
                        isShowingSound = true
                    } label: {
                        disclosureLabel("Sound", value: scheduleStore.notificationSound.title)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Choose the notification sound for all schedules")
                    if notificationCoordinator.deliveryState == .failed {
                        Button("Retry Reminder Delivery") {
                            Task { await notificationCoordinator.reconcileOnForeground() }
                        }
                    }
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
            .sheet(isPresented: $isShowingSchedule) {
                NavigationStack {
                    ScheduleView(
                        store: scheduleStore,
                        notificationCoordinator: notificationCoordinator
                    )
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { isShowingSchedule = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $isEditingName) {
                NameEditorView(notificationCoordinator: notificationCoordinator)
            }
            .sheet(isPresented: $isShowingSound) {
                NavigationStack {
                    NotificationSoundPickerView(coordinator: notificationCoordinator)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { isShowingSound = false }
                                .disabled(notificationCoordinator.isUpdating)
                        }
                    }
                }
                .interactiveDismissDisabled(notificationCoordinator.isUpdating)
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
            "Restore Bundled Affirmations"
        case .schedule:
            "Reset Schedules"
        case .all:
            "Reset All App Data"
        }
    }

    var title: String {
        switch self {
        case .affirmations:
            "Restore Bundled Affirmations?"
        case .schedule:
            "Reset Schedules?"
        case .all:
            "Reset All App Data?"
        }
    }

    var confirmationLabel: String {
        switch self {
        case .affirmations:
            "Restore Bundled Affirmations"
        case .schedule:
            "Reset Schedules"
        case .all:
            "Reset Everything"
        }
    }

    var message: String {
        switch self {
        case .affirmations:
            "This restores bundled affirmations, including deleted ones. Personal additions and favorites are kept."
        case .schedule:
            "This replaces all schedules with one disabled default schedule and removes pending notifications."
        case .all:
            "This restores the affirmation library, notification schedules and sound, affirmation selection, name, and theme to their defaults. Custom affirmations and favorites will be removed, and pending notifications will be cancelled."
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
