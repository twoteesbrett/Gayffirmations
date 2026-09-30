import SwiftUI

struct AffirmationSelectionView: View {
    let affirmationStore: AffirmationStore
    let notificationCoordinator: NotificationCoordinator

    @State private var isSaving = false
    @State private var errorMessage: String?

    private var selection: AffirmationSelection {
        notificationCoordinator.selectionStore.selection
    }

    private var tagChoices: [String] {
        var tags = affirmationStore.availableTags.filter { !selection.containsTag($0) }
        tags.append(contentsOf: selection.selectedTags)
        return tags.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    var body: some View {
        Form {
            Section {
                Button {
                    saveSelection(.all)
                } label: {
                    HStack {
                        Text("All affirmations")
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        if selection == .all {
                            Image(systemName: "checkmark")
                                .accessibilityHidden(true)
                        }
                    }
                }
                .foregroundStyle(.primary)
                .accessibilityLabel("All affirmations")
                .accessibilityHint("Uses every entry in Today and daily reminders")
                .accessibilityAddTraits(selection == .all ? .isSelected : [])

                Toggle("Favourites", isOn: Binding(
                    get: { selection.includesFavourites },
                    set: { saveSelection(selection.selectingFavourites($0)) }
                ))
                ForEach(tagChoices, id: \.self) { tag in
                    Toggle(isOn: Binding(
                        get: { selection.containsTag(tag) },
                        set: { saveSelection(selection.selectingTag(tag, included: $0)) }
                    )) {
                        Text("Tag: \(tag)")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } footer: {
                Text("Choose all affirmations, or combine favourites and tags. Entries matching any choice appear in Today and daily reminders, once each. Library filters are independent.")
            }

            Section {
                LabeledContent("Matching affirmations", value: "\(notificationCoordinator.selectedAffirmations.count)")
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Matching affirmations")
                    .accessibilityValue("\(notificationCoordinator.selectedAffirmations.count)")
                if notificationCoordinator.selectedAffirmations.isEmpty {
                    Text(selection.emptyMessage)
                    Text("Enabled reminders pause until matching entries return.")
                        .foregroundStyle(.secondary)
                }
                if isSaving {
                    ProgressView("Updating selection…")
                }
            }
        }
        .disabled(isSaving || notificationCoordinator.isUpdating)
        .navigationTitle("Affirmation Selection")
        .alert("Unable to Change Selection", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func saveSelection(_ updatedSelection: AffirmationSelection) {
        guard !isSaving else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await notificationCoordinator.setSelection(updatedSelection)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview("Long tags at largest text size") {
    let store = AffirmationStore(affirmations: [
        Affirmation(text: "I can take this one step at a time.", tags: ["Finding calm during a busy working day"])
    ])
    let coordinator = NotificationCoordinator(
        affirmationStore: store,
        scheduleStore: ScheduleStore(),
        scheduler: LocalNotificationService(),
        selectionStore: AffirmationSelectionStore(selection: .sources(
            favourites: true,
            tags: ["A selected tag with no remaining affirmations"]
        ))
    )
    NavigationStack {
        AffirmationSelectionView(affirmationStore: store, notificationCoordinator: coordinator)
    }
    .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("No sources selected") {
    let store = AffirmationStore(affirmations: Affirmation.samples)
    let coordinator = NotificationCoordinator(
        affirmationStore: store,
        scheduleStore: ScheduleStore(),
        scheduler: LocalNotificationService(),
        selectionStore: AffirmationSelectionStore(selection: .sources(favourites: false, tags: []))
    )
    NavigationStack {
        AffirmationSelectionView(affirmationStore: store, notificationCoordinator: coordinator)
    }
}
