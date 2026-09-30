import SwiftUI

struct ScheduleView: View {
    let store: ScheduleStore
    let notificationCoordinator: NotificationCoordinator

    @State private var presentedError: PresentedError?
    @State private var isUpdatingSchedule = false

    private let calculator = ScheduleCalculator()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Daily reminders", isOn: enabledBinding)
                } footer: {
                    if isUpdatingSchedule {
                        ProgressView("Updating schedule…")
                    } else {
                        Text("Selfsaid will ask for permission when you enable reminders.")
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
            .disabled(isUpdatingSchedule)
            .navigationTitle("Schedule")
            .alert(item: $presentedError) { presentedError in
                Alert(
                    title: Text(presentedError.title),
                    message: Text(presentedError.message),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let times = try? calculator.notificationTimes(for: store.schedule) {
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
        guard !isUpdatingSchedule else {
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
                    message: error.localizedDescription
                )
            }
        }
    }
}

#Preview {
    let affirmationStore = AffirmationStore(affirmations: Affirmation.samples)
    let scheduleStore = ScheduleStore()

    ScheduleView(
        store: scheduleStore,
        notificationCoordinator: NotificationCoordinator(
            affirmationStore: affirmationStore,
            scheduleStore: scheduleStore,
            scheduler: LocalNotificationService()
        )
    )
}

private struct PresentedError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
