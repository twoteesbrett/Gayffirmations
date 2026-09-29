import SwiftUI

struct ScheduleView: View {
    @State private var schedule = AffirmationSchedule()

    private let calculator = ScheduleCalculator()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Daily reminders", isOn: $schedule.isEnabled)
                } footer: {
                    Text("Notification delivery will be connected in the next milestone.")
                }

                Section("Daily period") {
                    DatePicker(
                        "Start",
                        selection: timeBinding(for: \AffirmationSchedule.startTime),
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "End",
                        selection: timeBinding(for: \AffirmationSchedule.endTime),
                        displayedComponents: .hourAndMinute
                    )
                }

                Section("Frequency") {
                    Stepper(
                        "\(schedule.notificationsPerDay) per day",
                        value: $schedule.notificationsPerDay,
                        in: 0...12
                    )
                }

                Section("Preview") {
                    preview
                }
            }
            .navigationTitle("Schedule")
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let times = try? calculator.notificationTimes(for: schedule) {
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

    private func timeBinding(
        for keyPath: WritableKeyPath<AffirmationSchedule, TimeOfDay>
    ) -> Binding<Date> {
        Binding(
            get: {
                schedule[keyPath: keyPath].date()
            },
            set: { date in
                schedule[keyPath: keyPath] = TimeOfDay(date: date)
            }
        )
    }
}

#Preview {
    ScheduleView()
}
