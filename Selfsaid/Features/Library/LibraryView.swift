import SwiftUI

struct LibraryView: View {
    let store: AffirmationStore

    @State private var editorDestination: EditorDestination?
    @State private var persistenceErrorMessage: String?
    @State private var filter: LibraryFilter = .all

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Show affirmations", selection: $filter) {
                    Text("All").tag(LibraryFilter.all)
                    Text("Favourites").tag(LibraryFilter.favourites)
                }
                .pickerStyle(.segmented)
                .padding()

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
                        Label("No Favourites", systemImage: "heart")
                    } description: {
                        Text("Tap the heart beside an affirmation to find it here.")
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

    private var filteredAffirmations: [Affirmation] {
        switch filter {
        case .all:
            store.affirmations
        case .favourites:
            store.affirmations.filter(\.isFavorite)
        }
    }

    private var affirmationList: some View {
        List(filteredAffirmations) { affirmation in
            HStack(spacing: 12) {
                Button {
                    editorDestination = .edit(affirmation)
                } label: {
                    Text(affirmation.text)
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
            AffirmationEditorView { text in
                try store.add(text: text)
            }
        case .edit(let affirmation):
            AffirmationEditorView(affirmation: affirmation) { text in
                try store.update(id: affirmation.id, text: text)
            }
        }
    }
}

private enum LibraryFilter: Hashable {
    case all
    case favourites
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

#Preview("Accessibility text size") {
    LibraryView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.dynamicTypeSize, .accessibility5)
}
