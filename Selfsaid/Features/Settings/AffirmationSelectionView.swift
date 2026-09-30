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
                        Spacer()
                        if selection == .all {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .foregroundStyle(.primary)
                .accessibilityAddTraits(selection == .all ? .isSelected : [])

                Toggle("Favourites", isOn: Binding(
                    get: { selection.includesFavourites },
                    set: { saveSelection(selection.selectingFavourites($0)) }
                ))
                ForEach(tagChoices, id: \.self) { tag in
                    Toggle("Tag: \(tag)", isOn: Binding(
                        get: { selection.containsTag(tag) },
                        set: { saveSelection(selection.selectingTag(tag, included: $0)) }
                    ))
                }
            } footer: {
                Text("Choose all affirmations, or combine favourites and tags. Entries matching any choice appear in Today and daily reminders, once each. Library filters are independent.")
            }

            Section {
                LabeledContent("Matching affirmations", value: "\(notificationCoordinator.selectedAffirmations.count)")
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
