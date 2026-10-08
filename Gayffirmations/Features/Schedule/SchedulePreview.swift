import SwiftUI

struct SchedulePreview: View {
    let schedule: AffirmationSchedule
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsExactTimes = false

    var body: some View {
        if let times = try? ScheduleCalculator().notificationTimes(for: schedule) {
            reminderTimeline(times)
            DisclosureGroup("Exact times", isExpanded: $showsExactTimes) {
                ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                    LabeledContent("Reminder \(index + 1)") {
                        Text(time.date(), format: .dateTime.hour().minute())
                    }
                }
            }
        }
    }

    private func reminderTimeline(_ times: [TimeOfDay]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(times.count) reminders per day")
            GeometryReader { geometry in
                let start = schedule.startTime.minutesSinceMidnight
                let duration = schedule.endTime.minutesSinceMidnight - start
                let width = max(0, geometry.size.width - 12)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.2))
                        .frame(height: 2)
                    ForEach(Array(times.enumerated()), id: \.offset) { _, time in
                        Circle()
                            .fill(.tint)
                            .frame(width: 12, height: 12)
                            .offset(x: width * Double(time.minutesSinceMidnight - start) / Double(duration))
                    }
                }
                .frame(height: 32)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: times)
            }
            .frame(height: 32)
            HStack {
                Text(schedule.startTime.date(), format: .dateTime.hour().minute())
                Spacer()
                Text(schedule.endTime.date(), format: .dateTime.hour().minute())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reminder timeline")
        .accessibilityValue(times.map { $0.date().formatted(date: .omitted, time: .shortened) }.joined(separator: ", "))
    }

}
