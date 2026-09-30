import SwiftUI

struct LibraryView: View {
    let store: AffirmationStore

    @Environment(\.appTheme) private var appTheme

    @State private var editorDestination: EditorDestination?
    @State private var persistenceErrorMessage: String?
    @State private var filter: AffirmationSelection = .all
    @State private var isTagPickerPresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

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
                } else if filteredAffirmations.isEmpty {
                    ContentUnavailableView {
                        Label(isTagFilter ? "No Matching Affirmations" : "No Favourites",
                              systemImage: isTagFilter ? "tag" : "heart")
                    } description: {
                        if isTagFilter {
                            Text("No affirmations match your chosen favourites or tags. Change the filters or add matching entries.")
                        } else {
                            Text("Tap the heart beside an affirmation to find it here.")
                        }
                    } actions: {
                        Button("Show All Affirmations") {
                            filter = .all
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    affirmationList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Library")
            .toolbar {
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
                isPresented: persistenceErrorIsPresented
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(persistenceErrorMessage ?? "Please try again.")
            }
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { filterControls }
                VStack(alignment: .leading, spacing: 8) { filterControls }
            }

            if isTagFilter {
                HStack(alignment: .top, spacing: 12) {
                    Text(filter.selectedTags.map { $0.lowercased() }.joined(separator: ", "))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button("Clear") { filter = .all }
                        .font(.subheadline)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Clear library filters")
                }
            }

            Text("\(filteredAffirmations.count) \(filteredAffirmations.count == 1 ? "affirmation" : "affirmations")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var filterControls: some View {
        Group {
            filterButton("All", systemImage: "square.stack", isSelected: filter == .all) {
                filter = .all
            }
            filterButton("Favourites", systemImage: "heart", isSelected: filter.includesFavourites) {
                updateFilter(filter.selectingFavourites(!filter.includesFavourites))
            }
            filterButton("Tags", systemImage: "tag", isSelected: isTagFilter) {
                isTagPickerPresented = true
            }
        }
    }

    private var tagChoices: [String] {
        let available = store.availableTags.filter { !filter.containsTag($0) }
        return (available + filter.selectedTags)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private var tagPicker: some View {
        NavigationStack {
            Form {
                Section {
                    if tagChoices.isEmpty {
                        Text("Add tags to affirmations in the editor to find them here.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(tagChoices, id: \.self) { tag in
                        Toggle(isOn: Binding(
                            get: { filter.containsTag(tag) },
                            set: { updateFilter(filter.selectingTag(tag, included: $0)) }
                        )) {
                            Text(tag.lowercased())
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } footer: {
                    Text("Show affirmations matching any selected tag or Favourites. These filters only change Library browsing.")
                }
            }
            .navigationTitle("Filter by Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isTagPickerPresented = false }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear Tags") {
                        updateFilter(.sources(favourites: filter.includesFavourites, tags: []))
                    }
                    .disabled(!isTagFilter)
                }
            }
        }
    }

    private func filterButton(
        _ title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: true, vertical: false)
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

    private func updateFilter(_ selection: AffirmationSelection) {
        // With no browsing filters selected, show the whole library.
        filter = selection.includesFavourites || !selection.selectedTags.isEmpty ? selection : .all
    }

    private var isTagFilter: Bool {
        !filter.selectedTags.isEmpty
    }

    private var filteredAffirmations: [Affirmation] {
        filter.matchingAffirmations(in: store.affirmations)
    }

    private var affirmationList: some View {
        List(filteredAffirmations) { affirmation in
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
        .listStyle(.insetGrouped)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollContentBackground(.hidden)
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

#Preview("With affirmations") {
    LibraryView(store: AffirmationStore(affirmations: Affirmation.samples))
}

#Preview("Empty") {
    LibraryView(store: AffirmationStore())
}

#Preview("With favourites") {
    LibraryView(store: AffirmationStore(affirmations: [
        Affirmation(text: "I can take this one step at a time.", isFavorite: true),
        Affirmation(text: "My effort matters.")
    ]))
}

#Preview("With tags") {
    LibraryView(store: AffirmationStore(affirmations: [
        Affirmation(text: "I can take this one step at a time.", tags: ["Calm", "Work"]),
        Affirmation(text: "My effort matters.", isFavorite: true, tags: ["Confidence"])
    ]))
}

#Preview("Accessibility text size") {
    LibraryView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Long tags at largest text size") {
    LibraryView(store: AffirmationStore(affirmations: [
        Affirmation(
            text: "I can make room for a quiet moment, even on a busy day.",
            isFavorite: true,
            tags: ["Finding calm during a busy working day", "Confidence"]
        )
    ]))
    .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Midnight") {
    LibraryView(store: AffirmationStore(affirmations: [
        Affirmation(text: "My effort matters.", isFavorite: true, tags: ["Confidence"]),
        Affirmation(text: "I can take this one step at a time.", tags: ["Calm", "Work"])
    ]))
    .environment(\.appTheme, .midnight)
    .tint(AppTheme.midnight.accentColor)
    .preferredColorScheme(.dark)
}
