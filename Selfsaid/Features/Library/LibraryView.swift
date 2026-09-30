import SwiftUI

struct LibraryView: View {
    let store: AffirmationStore

    @State private var editorDestination: EditorDestination?
    @State private var persistenceErrorMessage: String?
    @State private var filter: LibraryFilter = .all

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !store.availableTags.isEmpty || isTagFilter {
                    Picker("Show affirmations", selection: $filter) {
                        Text("All").tag(LibraryFilter.all)
                        Text("Favourites").tag(LibraryFilter.favourites)
                        ForEach(store.availableTags, id: \.self) { tag in
                            Text(tag).tag(LibraryFilter.tag(tag))
                        }
                        if case .tag(let tag) = filter, !store.availableTags.contains(tag) {
                            Text(tag).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                } else {
                    Picker("Show affirmations", selection: $filter) {
                        Text("All").tag(LibraryFilter.all)
                        Text("Favourites").tag(LibraryFilter.favourites)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }

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
                        if case .tag(let tag) = filter {
                            Text("No affirmations currently use the tag “\(tag)”.")
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

    private var isTagFilter: Bool {
        if case .tag = filter { return true }
        return false
    }

    private var filteredAffirmations: [Affirmation] {
        switch filter {
        case .all:
            store.affirmations
        case .favourites:
            store.affirmations.filter(\.isFavorite)
        case .tag(let tag):
            store.affirmations(tagged: tag)
        }
    }

    private var affirmationList: some View {
        List(filteredAffirmations) { affirmation in
            HStack(spacing: 12) {
                Button {
                    editorDestination = .edit(affirmation)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(affirmation.text)
                        if !affirmation.tags.isEmpty {
                            Text(affirmation.tags.joined(separator: " · "))
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
                        .foregroundStyle(affirmation.isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    affirmation.isFavorite ? "Remove from favorites" : "Add to favorites"
                )
            }
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

private enum LibraryFilter: Hashable {
    case all
    case favourites
    case tag(String)
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
