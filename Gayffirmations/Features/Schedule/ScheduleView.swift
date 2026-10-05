import SwiftUI
import UIKit

struct ScheduleView: View {
    let store: ScheduleStore
    let notificationCoordinator: NotificationCoordinator

    @State private var presentedError: PresentedError?
    @State private var isUpdatingSchedule = false
    @State private var showsExactTimes = false
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let calculator = ScheduleCalculator()

    var body: some View {
        Form {
            Section {
                Toggle("Daily reminders", isOn: enabledBinding)
            } footer: {
                if isUpdatingSchedule {
                    ProgressView("Updating schedule…")
                } else if notificationCoordinator.deliveryIsPaused {
                    Text("Reminders are paused because no selected affirmations are ready. Add matching entries or set your name in Settings to use personalised messages.")
                } else {
                    Text("Gayffirmations will ask for permission when you enable reminders.")
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
                    in: AffirmationSchedule.notificationCountRange
                )
            }

            Section {
                if dynamicTypeSize.isAccessibilitySize {
                    rhythmPicker.pickerStyle(.menu)
                } else {
                    rhythmPicker.pickerStyle(.segmented)
                }

                if store.schedule.rhythm != .evenlySpaced {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emphasis")
                        if dynamicTypeSize.isAccessibilitySize {
                            emphasisPicker.pickerStyle(.menu)
                        } else {
                            emphasisPicker.pickerStyle(.segmented)
                        }
                    }
                }
            } header: {
                Text("Daily rhythm")
            } footer: {
                Text(store.schedule.rhythm.explanation)
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
            Text("No reminders will be delivered until the selected source has affirmations ready to use.")
                .foregroundStyle(.secondary)
        } else {
            schedulePreview
        }
    }

    @ViewBuilder
    private var schedulePreview: some View {
        switch Result(catching: { try calculator.notificationTimes(for: store.schedule) }) {
        case .success(let times):
            if times.isEmpty {
                Text("No reminders are scheduled.")
                    .foregroundStyle(.secondary)
            } else {
                reminderTimeline(times)

                DisclosureGroup("Exact times", isExpanded: $showsExactTimes) {
                    ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                        LabeledContent("Reminder \(index + 1)") {
                            Text(time.date(), format: .dateTime.hour().minute())
                        }
                    }
                }
            }
        case .failure(let error):
            Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    private var rhythmPicker: some View {
        Picker("Daily rhythm", selection: rhythmBinding) {
            ForEach([ScheduleRhythm.moreEarly, .evenlySpaced, .moreLate]) { rhythm in
                Text(rhythm.title).tag(rhythm)
            }
        }
    }

    private var emphasisPicker: some View {
        Picker("Emphasis", selection: emphasisBinding) {
            ForEach(ScheduleEmphasis.allCases) { emphasis in
                Text(emphasis.title).tag(emphasis)
            }
        }
    }

    private func reminderTimeline(_ times: [TimeOfDay]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(times.count) reminders per day")
            GeometryReader { geometry in
                let start = store.schedule.startTime.minutesSinceMidnight
                let duration = store.schedule.endTime.minutesSinceMidnight - start
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
                Text(store.schedule.startTime.date(), format: .dateTime.hour().minute())
                Spacer()
                Text(store.schedule.endTime.date(), format: .dateTime.hour().minute())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reminder timeline")
        .accessibilityValue(times.map { $0.date().formatted(date: .omitted, time: .shortened) }.joined(separator: ", "))
    }

    private var rhythmBinding: Binding<ScheduleRhythm> {
        Binding(
            get: { store.schedule.rhythm },
            set: { rhythm in
                performScheduleChange {
                    try await notificationCoordinator.setRhythm(rhythm)
                }
            }
        )
    }

    private var emphasisBinding: Binding<ScheduleEmphasis> {
        Binding(
            get: { store.schedule.emphasis },
            set: { emphasis in
                performScheduleChange {
                    try await notificationCoordinator.setEmphasis(emphasis)
                }
            }
        )
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { store.schedule.isEnabled },
            set: { isEnabled in
                performScheduleChange {
                    try await notificationCoordinator.setEnabled(isEnabled)
                }
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

private struct PresentedError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let offersSettings: Bool
}

#if DEBUG
#Preview {
    let affirmationStore = AffirmationStore(affirmations: PreviewContent.affirmations)
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
    let affirmationStore = AffirmationStore(affirmations: PreviewContent.affirmations)
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

#Preview("More late") {
    let affirmationStore = AffirmationStore(affirmations: PreviewContent.affirmations)
    let scheduleStore = ScheduleStore(schedule: AffirmationSchedule(
        endTime: TimeOfDay(hour: 23, minute: 0),
        notificationsPerDay: 6,
        rhythm: .moreLate
    ))

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

#endif
