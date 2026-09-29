import SwiftUI

struct ScheduleView: View {
    let store: ScheduleStore

    @State private var persistenceErrorMessage: String?

    private let calculator = ScheduleCalculator()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Daily reminders", isOn: enabledBinding)
                } footer: {
                    Text("Notification delivery will be connected in the next milestone.")
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
            .navigationTitle("Schedule")
            .alert(
                "Unable to Save",
                isPresented: persistenceErrorIsPresented
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(persistenceErrorMessage ?? "Please try again.")
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
                performPersistedChange {
                    try store.setEnabled(isEnabled)
                }
            }
        )
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: { store.schedule.startTime.date() },
            set: { date in
                performPersistedChange {
                    try store.setStartTime(TimeOfDay(date: date))
                }
            }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: { store.schedule.endTime.date() },
            set: { date in
                performPersistedChange {
                    try store.setEndTime(TimeOfDay(date: date))
                }
            }
        )
    }

    private var notificationsPerDayBinding: Binding<Int> {
        Binding(
            get: { store.schedule.notificationsPerDay },
            set: { notificationsPerDay in
                performPersistedChange {
                    try store.setNotificationsPerDay(notificationsPerDay)
                }
            }
        )
    }

    private var persistenceErrorIsPresented: Binding<Bool> {
        Binding(
            get: { persistenceErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    persistenceErrorMessage = nil
                }
            }
        )
    }

    private func performPersistedChange(_ change: () throws -> Void) {
        do {
            try change()
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ScheduleView(store: ScheduleStore())
}
