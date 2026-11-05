import SwiftUI

struct FallbackAffirmationsView: View {
    let coordinator: NotificationCoordinator
    @State private var errorMessage: String?

    private var selection: AffirmationSelection {
        coordinator.fallbackSelectionStore.selection
    }

    var body: some View {
        Form {
            Section {
                Button {
                    select(.all)
                } label: {
                    HStack {
                        Text("All affirmations")
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection == .all {
                            Image(systemName: "checkmark")
                                .accessibilityHidden(true)
                        }
                    }
                }
                .accessibilityAddTraits(selection == .all ? .isSelected : [])

                Toggle("Favourites", isOn: Binding(
                    get: { selection.includesFavourites },
                    set: { select(selection.selectingFavourites($0)) }
                ))
            } footer: {
                Text("Choose what appears on Today outside active schedule windows or when no active schedule has matching affirmations. Affirmations matching any selected tag or Favourites are included once. Clearing every filter returns to All.")
            }

            TagSelectionSection(
                tags: TagChoices.sortedUnique(coordinator.availableTags + selection.selectedTags),
                selection: selection,
                onChange: select
            )

            Section {
                Text("\(coordinator.fallbackAffirmations.count) matching affirmations ready")
                if coordinator.fallbackAffirmations.isEmpty {
                    Text("No matching affirmations are ready. Add matching entries in Library, choose All, or set your name in Settings for personalised messages.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .themedBackground()
        .navigationTitle("Default Affirmations")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(coordinator.isUpdating)
        .alert("Unable to Save Default Affirmations", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func select(_ selection: AffirmationSelection) {
        do {
            try coordinator.setFallbackSelection(selection)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
