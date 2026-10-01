import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    let store: AffirmationStore
    let notificationCoordinator: NotificationCoordinator

    @Environment(\.appTheme) private var appTheme

    @State private var editorDestination: EditorDestination?
    @State private var persistenceErrorMessage: String?
    @State private var isSavingSelection = false
    @State private var isTagPickerPresented = false

    private var selection: AffirmationSelection {
        notificationCoordinator.selectionStore.selection
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    selectionBar
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 12, trailing: 4))
                }

                Section {
                    if store.affirmations.isEmpty {
                        ContentUnavailableView {
                            Label("No Affirmations", systemImage: "text.quote")
                        } description: {
                            Text("Add an affirmation to begin.")
                        } actions: {
                            Button("Add Affirmation", systemImage: "plus") {
                                editorDestination = .new
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else if selectedAffirmations.isEmpty {
                        ContentUnavailableView {
                            Label("No Matching Affirmations", systemImage: "text.quote")
                        } description: {
                            Text(selection.emptyMessage)
                        } actions: {
                            Button("Show All Affirmations") {
                                saveSelection(.all)
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        affirmationList
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.top, 0, for: .scrollContent)
            .themedBackground()
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Affirmation", systemImage: "plus") {
                        editorDestination = .new
                    }
                }
            }
            .sheet(item: $editorDestination) { destination in
                editor(for: destination)
            }
            .sheet(isPresented: $isTagPickerPresented) {
                tagPicker
            }
            .alert(
                "Unable to Save",
                isPresented: errorIsPresented(inTagPicker: false)
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(persistenceErrorMessage ?? "Please try again.")
            }
            .disabled(isSavingSelection || notificationCoordinator.isUpdating)
        }
    }

    private var selectionBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            WrappingLayout(spacing: 8) {
                selectionControls
            }

            if hasSelectedTags {
                Text(selection.selectedTags.map { $0.lowercased() }.joined(separator: ", "))
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("These affirmations appear in Today and reminders.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if isSavingSelection {
                ProgressView("Updating selection…")
            }

            Text("\(selectedAffirmations.count) \(selectedAffirmations.count == 1 ? "affirmation" : "affirmations")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var selectionControls: some View {
        Group {
            selectionButton("All", systemImage: "square.stack", isSelected: selection == .all) {
                saveSelection(.all)
            }
            selectionButton("Favourites", systemImage: "heart", isSelected: selection.includesFavourites) {
                saveSelection(selection.selectingFavourites(!selection.includesFavourites))
            }
            selectionButton("Tags", systemImage: "tag", isSelected: hasSelectedTags) {
                isTagPickerPresented = true
            }
        }
    }

    private var tagChoices: [String] {
        TagPreset.tagChoices(from: selection.selectedTags + store.availableTags)
    }

    private var tagPicker: some View {
        NavigationStack {
            Form {
                Section {
                    if isSavingSelection {
                        ProgressView("Updating selection…")
                    }
                    if tagChoices.isEmpty {
                        Text("Add tags to affirmations in the editor to find them here.")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Choose a preset or tags. Entries matching any selected tag or Favourites appear in Library, Today, and reminders.")
                }
                TagSelectionSection(
                    tags: tagChoices,
                    selection: selection,
                    onChange: saveSelection
                )
            }
            .themedBackground()
            .disabled(isSavingSelection || notificationCoordinator.isUpdating)
            .navigationTitle("Presets & Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isTagPickerPresented = false }
                }
            }
            .alert("Unable to Change Selection", isPresented: errorIsPresented(inTagPicker: true)) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(persistenceErrorMessage ?? "Please try again.")
            }
        }
    }

    private func selectionButton(
        _ title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? appTheme.accentColor : Color.primary)
            .background {
                Capsule()
                    .fill(isSelected ? appTheme.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground))
            }
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? appTheme.accentColor : Color.primary.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func saveSelection(_ selection: AffirmationSelection) {
        guard !isSavingSelection, !notificationCoordinator.isUpdating else { return }
        isSavingSelection = true
        Task {
            defer { isSavingSelection = false }
            do {
                try await notificationCoordinator.setSelection(selection.usingAllWhenEmpty)
            } catch {
                persistenceErrorMessage = error.localizedDescription
            }
        }
    }

    private var hasSelectedTags: Bool {
        !selection.selectedTags.isEmpty
    }

    private var selectedAffirmations: [Affirmation] {
        selection.matchingAffirmations(in: store.affirmations)
    }

    private var affirmationList: some View {
        ForEach(selectedAffirmations) { affirmation in
            HStack(spacing: 12) {
                Button {
                    editorDestination = .edit(affirmation)
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(affirmation.text)
                            .font(.body)
                            .lineSpacing(3)
                        if !affirmation.tags.isEmpty {
                            Text(affirmation.tags.map { $0.lowercased() }.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the affirmation editor")

                Button {
                    performPersistedChange {
                        try store.toggleFavorite(id: affirmation.id)
                    }
                } label: {
                    Image(systemName: affirmation.isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(affirmation.isFavorite ? appTheme.accentColor : Color.secondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    affirmation.isFavorite ? "Remove from favorites" : "Add to favorites"
                )
            }
            .padding(.vertical, 8)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
            .swipeActions(edge: .leading) {
                Button("Edit", systemImage: "pencil") {
                    editorDestination = .edit(affirmation)
                }
                .tint(.blue)
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    performPersistedChange {
                        try store.delete(id: affirmation.id)
                    }
                }
            }
        }
    }

    private func errorIsPresented(inTagPicker: Bool) -> Binding<Bool> {
        Binding(
            get: { persistenceErrorMessage != nil && isTagPickerPresented == inTagPicker },
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

    @ViewBuilder
    private func editor(for destination: EditorDestination) -> some View {
        switch destination {
        case .new:
            AffirmationEditorView(availableTags: store.availableTags) { text, tags in
                try store.add(text: text, tags: tags)
            }
        case .edit(let affirmation):
            AffirmationEditorView(affirmation: affirmation, availableTags: store.availableTags) { text, tags in
                try store.update(id: affirmation.id, text: text, tags: tags)
            }
        }
    }
}

private enum EditorDestination: Identifiable {
    case new
    case edit(Affirmation)

    var id: String {
        switch self {
        case .new:
            "new"
        case .edit(let affirmation):
            affirmation.id.uuidString
        }
    }
}

#Preview("All affirmations") {
    libraryPreview()
}

#Preview("Favourites") {
    libraryPreview(
        affirmations: [Affirmation(text: "My effort matters.", isFavorite: true)],
        selection: .favourites
    )
}

#Preview("Missing selected tag") {
    libraryPreview(selection: .tag("A tag with no matching entries"))
}

#Preview("Custom tags only") {
    libraryPreview(affirmations: [Affirmation(text: "I can take my time.", tags: ["Work"])])
}

#Preview("Empty library") {
    libraryPreview(affirmations: [])
}

#Preview("All selected tags at largest text size") {
    libraryPreview(selection: .sources(favourites: false, tags: TagPreset.predefined.flatMap(\.tags)))
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Midnight") {
    libraryPreview()
        .environment(\.appTheme, .midnight)
        .tint(AppTheme.midnight.accentColor)
        .preferredColorScheme(.dark)
}

@MainActor
private func libraryPreview(
    affirmations: [Affirmation]? = nil,
    selection: AffirmationSelection = .all
) -> LibraryView {
    let store = AffirmationStore(affirmations: affirmations ?? Affirmation.samples)
    let coordinator = NotificationCoordinator(
        affirmationStore: store,
        scheduleStore: ScheduleStore(),
        scheduler: PreviewNotificationScheduler(),
        selectionStore: AffirmationSelectionStore(selection: selection)
    )
    return LibraryView(store: store, notificationCoordinator: coordinator)
}
