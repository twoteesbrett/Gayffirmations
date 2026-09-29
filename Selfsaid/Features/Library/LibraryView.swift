import SwiftUI

struct LibraryView: View {
    let store: AffirmationStore

    @State private var editorDestination: EditorDestination?

    var body: some View {
        NavigationStack {
            Group {
                if store.affirmations.isEmpty {
                    ContentUnavailableView(
                        "No Affirmations",
                        systemImage: "text.quote",
                        description: Text("Add an affirmation to begin.")
                    )
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
        }
    }

    private var affirmationList: some View {
        List(store.affirmations) { affirmation in
            HStack(spacing: 12) {
                Text(affirmation.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editorDestination = .edit(affirmation)
                    }

                Button {
                    store.toggleFavorite(id: affirmation.id)
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
                    store.delete(id: affirmation.id)
                }
            }
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

#Preview {
    LibraryView(store: AffirmationStore(affirmations: Affirmation.samples))
}
