import SwiftUI
import UIKit

struct ScheduleView: View {
    let store: ScheduleStore
    let notificationCoordinator: NotificationCoordinator

    @State private var editingSchedule: AffirmationSchedule?
    @State private var pendingDeletion: AffirmationSchedule?
    @State private var errorMessage: String?
    @State private var permissionDenied = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        let plan = notificationCoordinator.dailyPlan
        let deliveryMinutes = plan.map { $0.time.minutesSinceMidnight }
        let hasOverlappingReminders = Set(deliveryMinutes).count != deliveryMinutes.count

        List {
            Section {
                ForEach(store.schedules) { schedule in
                    scheduleRow(schedule)
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) { pendingDeletion = schedule }
                                .tint(.red)
                        }
                        .swipeActions(edge: .leading) {
                            Button("Duplicate", systemImage: "plus.square.on.square") { duplicate(schedule) }
                        }
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") { editingSchedule = schedule }
                            Button("Duplicate", systemImage: "plus.square.on.square") { duplicate(schedule) }
                            Button("Delete", systemImage: "trash", role: .destructive) { pendingDeletion = schedule }
                        }
                }
                Button("Add Schedule", systemImage: "plus") {
                    editingSchedule = AffirmationSchedule()
                }
            } footer: {
                Text("Each schedule has its own tags, times, and daily rhythm. Swipe right to duplicate a schedule, or left to delete it.")
            }

            Section {
                NavigationLink {
                    FallbackAffirmationsView(coordinator: notificationCoordinator)
                } label: {
                    LabeledContent("Affirmations", value: notificationCoordinator.fallbackSelectionStore.selection.name)
                }
            } header: {
                Text("When no schedule is active")
            } footer: {
                Text("Today uses this selection when no schedule has reminders ready to deliver, including paused schedules. It changes once per day and never sends reminders.")
            }

            Section("Daily preview") {
                LabeledContent("Enabled reminders", value: "\(notificationCoordinator.dailyTotal) of \(ScheduleValidation.dailyReminderLimit)")
                if plan.isEmpty {
                    Text("No reminders are ready to deliver. Enable a schedule with matching affirmations to see your day here.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(plan) { slot in
                        HStack(alignment: .firstTextBaseline) {
                            Text(slot.time.date(), format: .dateTime.hour().minute())
                                .monospacedDigit()
                            Spacer()
                            Text(store.schedules.first { $0.id == slot.scheduleID }?.summary ?? "")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    if hasOverlappingReminders {
                        Text("Some reminders share a time. Both schedules will deliver their reminders.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .themedBackground()
        .navigationTitle("Schedules")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(notificationCoordinator.isUpdating)
        .sheet(item: $editingSchedule) { schedule in
            ScheduleEditorView(schedule: schedule, coordinator: notificationCoordinator)
        }
        .confirmationDialog("Delete schedule?", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        ), titleVisibility: .visible) {
            if let schedule = pendingDeletion {
                Button("Delete \(schedule.summary)", role: .destructive) {
                    pendingDeletion = nil
                    perform { try await notificationCoordinator.deleteSchedule(id: schedule.id) }
                }
            }
        } message: {
            Text("This removes the schedule and its reminders.")
        }
        .alert("Unable to Update Schedules", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            if permissionDenied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func scheduleRow(_ schedule: AffirmationSchedule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: Binding(
                get: { schedule.isEnabled },
                set: { enabled in
                    perform { try await notificationCoordinator.setEnabled(enabled, for: schedule.id) }
                }
            )) {
                Text(schedule.timeRangeDescription).font(.headline)
            }
            Button {
                editingSchedule = schedule
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(schedule.selection.name)
                        Text("\(schedule.notificationsPerDay) per day")
                        Text(schedule.rhythm.title)
                        if notificationCoordinator.isPaused(schedule) {
                            Label("Paused · No matching affirmations ready", systemImage: "pause.circle")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(schedule.summary)")
        }
    }

    private func duplicate(_ schedule: AffirmationSchedule) {
        var copy = schedule
        copy.id = UUID()
        copy.name = ""
        copy.isEnabled = false
        editingSchedule = copy
    }

    private func perform(_ change: @escaping @MainActor () async throws -> Void) {
        Task {
            do { try await change() }
            catch {
                permissionDenied = (error as? NotificationCoordinatorError) == .permissionDenied
                errorMessage = error.localizedDescription
            }
        }
    }
}

#if DEBUG
#Preview {
    let store = ScheduleStore()
    NavigationStack {
        ScheduleView(store: store, notificationCoordinator: NotificationCoordinator(
            affirmationStore: AffirmationStore(affirmations: PreviewContent.affirmations),
            scheduleStore: store, scheduler: PreviewNotificationScheduler()
        ))
    }
}
#endif
