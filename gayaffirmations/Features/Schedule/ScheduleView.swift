import SwiftUI
import UIKit

struct ScheduleView: View {
    let store: ScheduleStore
    let notificationCoordinator: NotificationCoordinator

    @State private var presentedError: PresentedError?
    @State private var isUpdatingSchedule = false
    @Environment(\.openURL) private var openURL

    private let calculator = ScheduleCalculator()

    var body: some View {
        Form {
            Section {
                Toggle("Daily reminders", isOn: enabledBinding)
            } footer: {
                if isUpdatingSchedule {
                    ProgressView("Updating schedule…")
                } else if notificationCoordinator.deliveryIsPaused {
                    Text("Reminders are paused because the selected source has no affirmations. They will resume when matching entries return.")
                } else {
                    Text("gayaffirmations will ask for permission when you enable reminders.")
                }
            }

            Section("Daily period") {
                DatePicker(
                    "Start",
                    selection: startTimeBinding,
                    displayedComponents: .hourAndMinute
                )

                DatePicker(
                    "End",
                    selection: endTimeBinding,
                    displayedComponents: .hourAndMinute
                )
            }

            Section("Frequency") {
                Stepper(
                    "\(store.schedule.notificationsPerDay) per day",
                    value: notificationsPerDayBinding,
                    in: 0...12
                )
            }

            Section("Preview") {
                preview
            }
        }
        .themedBackground()
        .disabled(isUpdatingSchedule || notificationCoordinator.isUpdating)
        .navigationTitle("Notification Schedule")
        .alert(item: $presentedError) { presentedError in
            alert(for: presentedError)
        }
    }

    @ViewBuilder
    private var preview: some View {
        if notificationCoordinator.deliveryIsPaused {
            Text("No reminders will be delivered until the selected source has entries.")
                .foregroundStyle(.secondary)
        } else if let times = try? calculator.notificationTimes(for: store.schedule) {
            if times.isEmpty {
                Text("No reminders are scheduled.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                    LabeledContent("Reminder \(index + 1)") {
                        Text(time.date(), format: .dateTime.hour().minute())
                    }
                }
            }
        } else {
            Label(
                ScheduleCalculatorError.endMustBeAfterStart.localizedDescription,
                systemImage: "exclamationmark.triangle"
            )
                .foregroundStyle(.red)
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { store.schedule.isEnabled },
            set: { isEnabled in
                updateNotifications(isEnabled: isEnabled)
            }
        )
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: { store.schedule.startTime.date() },
            set: { date in
                performScheduleChange {
                    try await notificationCoordinator.setStartTime(
                        TimeOfDay(date: date)
                    )
                }
            }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: { store.schedule.endTime.date() },
            set: { date in
                performScheduleChange {
                    try await notificationCoordinator.setEndTime(
                        TimeOfDay(date: date)
                    )
                }
            }
        )
    }

    private var notificationsPerDayBinding: Binding<Int> {
        Binding(
            get: { store.schedule.notificationsPerDay },
            set: { notificationsPerDay in
                performScheduleChange {
                    try await notificationCoordinator.setNotificationsPerDay(
                        notificationsPerDay
                    )
                }
            }
        )
    }

    private func updateNotifications(isEnabled: Bool) {
        performScheduleChange {
            try await notificationCoordinator.setEnabled(isEnabled)
        }
    }

    private func performScheduleChange(
        _ change: @escaping @MainActor () async throws -> Void
    ) {
        guard !isUpdatingSchedule, !notificationCoordinator.isUpdating else {
            return
        }

        isUpdatingSchedule = true

        Task {
            defer { isUpdatingSchedule = false }

            do {
                try await change()
            } catch {
                presentedError = PresentedError(
                    title: "Unable to Update Schedule",
                    message: error.localizedDescription,
                    offersSettings: (error as? NotificationCoordinatorError)
                        == .permissionDenied
                )
            }
        }
    }

    private func alert(for error: PresentedError) -> Alert {
        guard error.offersSettings else {
            return Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .cancel(Text("OK"))
            )
        }

        return Alert(
            title: Text("Notifications Are Off"),
            message: Text(error.message),
            primaryButton: .default(Text("Open Settings")) {
                openAppSettings()
            },
            secondaryButton: .cancel()
        )
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsURL)
    }
}

#Preview {
    let affirmationStore = AffirmationStore(affirmations: Affirmation.samples)
    let scheduleStore = ScheduleStore()

    NavigationStack {
        ScheduleView(
            store: scheduleStore,
            notificationCoordinator: NotificationCoordinator(
                affirmationStore: affirmationStore,
                scheduleStore: scheduleStore,
                scheduler: PreviewNotificationScheduler()
            )
        )
    }
}

#Preview("Accessibility text size") {
    let affirmationStore = AffirmationStore(affirmations: Affirmation.samples)
    let scheduleStore = ScheduleStore()

    NavigationStack {
        ScheduleView(
            store: scheduleStore,
            notificationCoordinator: NotificationCoordinator(
                affirmationStore: affirmationStore,
                scheduleStore: scheduleStore,
                scheduler: PreviewNotificationScheduler()
            )
        )
        .environment(\.dynamicTypeSize, .accessibility5)
    }
}

private struct PresentedError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let offersSettings: Bool
}
