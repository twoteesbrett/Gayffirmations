import SwiftUI
import UIKit

struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: AffirmationSchedule
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var permissionDenied = false
    @State private var enableLimitReached = false
    let coordinator: NotificationCoordinator

    init(schedule: AffirmationSchedule, coordinator: NotificationCoordinator) {
        _draft = State(initialValue: schedule)
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable", isOn: Binding(
                        get: { draft.isEnabled },
                        set: { enabled in
                            if enabled && otherEnabledReminderCount + draft.notificationsPerDay > ScheduleValidation.dailyReminderLimit {
                                enableLimitReached = true
                            } else {
                                draft.isEnabled = enabled
                                enableLimitReached = false
                            }
                        }
                    ))
                    if enableLimitReached {
                        limitMessage("Enabling this schedule would exceed the \(ScheduleValidation.dailyReminderLimit) daily reminder limit. Reduce this or another schedule’s frequency first.")
                    }
                }
                Section {
                    NavigationLink {
                        ScheduleContentPicker(selection: $draft.selection, availableTags: coordinator.availableTags)
                    } label: {
                        LabeledContent("Affirmations", value: draft.selection.name)
                    }
                } footer: {
                    Text("\(coordinator.matchingAffirmations(for: draft).count) matching affirmations ready. Choose multiple tags to include affirmations matching any of them.")
                }
                Section("Daily period") {
                    DatePicker("Start", selection: timeBinding(\.startTime), displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: timeBinding(\.endTime), displayedComponents: .hourAndMinute)
                }
                Section {
                    Stepper("\(draft.notificationsPerDay) per day", onIncrement: canIncreaseFrequency ? {
                        draft.notificationsPerDay += 1
                        enableLimitReached = false
                    } : nil, onDecrement: draft.notificationsPerDay > AffirmationSchedule.notificationCountRange.lowerBound ? {
                        draft.notificationsPerDay -= 1
                        enableLimitReached = false
                    } : nil)
                } header: {
                    Text("Frequency")
                } footer: {
                    Text("\(otherEnabledReminderCount + (draft.isEnabled ? draft.notificationsPerDay : 0)) daily reminders across enabled schedules. A maximum of \(ScheduleValidation.dailyReminderLimit) per day is permitted.")
                }
                Section {
                    if dynamicTypeSize.isAccessibilitySize {
                        rhythmPicker.pickerStyle(.menu)
                    } else {
                        rhythmPicker.pickerStyle(.segmented)
                    }
                    if draft.rhythm != .evenlySpaced {
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
                    Text(draft.rhythm.explanation)
                }
                Section("Preview") {
                    SchedulePreview(schedule: draft)
                    if coordinator.matchingAffirmations(for: draft).isEmpty {
                        Text("This schedule will pause until matching affirmations are ready. Add matching entries or set your name in Settings to use personalised messages.")
                            .foregroundStyle(.secondary)
                    } else if !draft.isEnabled {
                        Text("Enable this schedule to deliver at these times.")
                            .foregroundStyle(.secondary)
                    }
                    if let validationMessage {
                        Label(validationMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .themedBackground()
            .navigationTitle("Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving || validationMessage != nil)
                }
                ToolbarItem(placement: .status) {
                    if isSaving { ProgressView("Saving schedule") }
                }
            }
            .interactiveDismissDisabled(isSaving)
            .alert("Unable to Save Schedule", isPresented: Binding(
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
    }

    private var canIncreaseFrequency: Bool {
        draft.notificationsPerDay < AffirmationSchedule.notificationCountRange.upperBound
            && (!draft.isEnabled || otherEnabledReminderCount + draft.notificationsPerDay < ScheduleValidation.dailyReminderLimit)
    }

    private var otherEnabledReminderCount: Int {
        coordinator.scheduleStore.schedules
            .filter { $0.id != draft.id && $0.isEnabled }
            .reduce(0) { $0 + $1.notificationsPerDay }
    }

    private func limitMessage(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.footnote)
            .foregroundStyle(.red)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var validationMessage: String? {
        var schedules = coordinator.scheduleStore.schedules.filter { $0.id != draft.id }
        schedules.append(draft)
        do { try ScheduleValidation.validate(schedules); return nil }
        catch { return error.localizedDescription }
    }

    private var rhythmPicker: some View {
        Picker("Daily rhythm", selection: $draft.rhythm) {
            ForEach([ScheduleRhythm.moreEarly, .evenlySpaced, .moreLate]) { rhythm in
                Text(rhythm.title).tag(rhythm)
            }
        }
    }

    private var emphasisPicker: some View {
        Picker("Emphasis", selection: $draft.emphasis) {
            ForEach(ScheduleEmphasis.allCases) { emphasis in Text(emphasis.title).tag(emphasis) }
        }
    }

    private func timeBinding(_ keyPath: WritableKeyPath<AffirmationSchedule, TimeOfDay>) -> Binding<Date> {
        Binding(get: { draft[keyPath: keyPath].date() },
                set: { draft[keyPath: keyPath] = TimeOfDay(date: $0) })
    }

    private func save() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await coordinator.saveSchedule(draft)
                dismiss()
            } catch {
                permissionDenied = (error as? NotificationCoordinatorError) == .permissionDenied
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct ScheduleContentPicker: View {
    @Binding var selection: AffirmationSelection
    let availableTags: [String]

    var body: some View {
        Form {
            Section {
                Toggle("All affirmations", isOn: Binding(
                    get: { selection == .all },
                    set: { selection = $0 ? .all : .sources(favourites: false, tags: []) }
                ))
                Toggle("Favourites", isOn: Binding(
                    get: { selection.includesFavourites },
                    set: { selection = selection.selectingFavourites($0) }
                ))
            } footer: {
                Text("Affirmations matching any selected tag or Favourites are included once. With nothing selected, this schedule pauses.")
            }
            TagSelectionSection(
                tags: TagChoices.sortedUnique(availableTags + selection.selectedTags),
                selection: selection,
                onChange: { selection = $0 }
            )
        }
        .themedBackground()
        .navigationTitle("Affirmations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
