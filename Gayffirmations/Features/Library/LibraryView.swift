import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    let store: AffirmationStore
    let notificationCoordinator: NotificationCoordinator

    @Environment(\.appTheme) private var appTheme

    @State private var editorDestination: EditorDestination?
    @State private var persistenceErrorMessage: String?
    @State private var isTagPickerPresented = false

    @State private var filter: AffirmationSelection

    init(
        store: AffirmationStore,
        notificationCoordinator: NotificationCoordinator,
        initialFilter: AffirmationSelection = .all
    ) {
        self.store = store
        self.notificationCoordinator = notificationCoordinator
        _filter = State(initialValue: initialFilter)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    filterBar
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
                    } else if filteredAffirmations.isEmpty {
                        ContentUnavailableView {
                            Label("No Matching Affirmations", systemImage: "text.quote")
                        } description: {
                            Text(filter.emptyMessage)
                        } actions: {
                            Button("Show All Affirmations") {
                                setFilter(.all)
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
                isPresented: errorIsPresented
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(persistenceErrorMessage ?? "Please try again.")
            }
            .disabled(notificationCoordinator.isUpdating)
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            WrappingLayout(spacing: 8) {
                filterControls
            }

            if filter != .all {
                HStack(alignment: .firstTextBaseline) {
                    Text(filter.name)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button("Clear filters") { setFilter(.all) }
                }
                .font(.subheadline)
            }

            Text("Filter the list to find and edit affirmations. Choose Today’s content in Schedules.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("\(filteredAffirmations.count) \(filteredAffirmations.count == 1 ? "affirmation" : "affirmations")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var filterControls: some View {
        Group {
            filterButton("All", systemImage: "square.stack", isSelected: filter == .all) {
                setFilter(.all)
            }
            filterButton("Favourites", systemImage: "heart", isSelected: filter.includesFavourites) {
                setFilter(filter.selectingFavourites(!filter.includesFavourites))
            }
            filterButton("Tags", systemImage: "tag", isSelected: hasSelectedTags) {
                isTagPickerPresented = true
            }
        }
    }

    private var tagChoices: [String] {
        TagChoices.sortedUnique(filter.selectedTags + store.availableTags)
    }

    private var tagPicker: some View {
        NavigationStack {
            Form {
                Section {
                    if tagChoices.isEmpty {
                        Text("Add tags to affirmations in the editor to find them here.")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Show entries matching any selected tag or Favourites. These filters only change the Library list.")
                }
                TagSelectionSection(
                    tags: tagChoices,
                    selection: filter,
                    onChange: setFilter
                )
            }
            .themedBackground()
            .disabled(notificationCoordinator.isUpdating)
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isTagPickerPresented = false }
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

    private func setFilter(_ selection: AffirmationSelection) {
        filter = selection.usingAllWhenEmpty
    }

    private var hasSelectedTags: Bool {
        !filter.selectedTags.isEmpty
    }

    private var filteredAffirmations: [Affirmation] {
        filter.matchingAffirmations(in: store.affirmations)
    }

    private var affirmationList: some View {
        ForEach(filteredAffirmations) { affirmation in
            HStack(spacing: 12) {
                if affirmation.isBundled {
                    affirmationLabel(affirmation)
                } else {
                    Button {
                        editorDestination = .edit(affirmation)
                    } label: {
                        affirmationLabel(affirmation)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the affirmation editor")
                }

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
                if !affirmation.isBundled {
                    Button("Edit", systemImage: "pencil") {
                        editorDestination = .edit(affirmation)
                    }
                    .tint(appTheme.accentColor)
                }
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

    private func affirmationLabel(_ affirmation: Affirmation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(affirmation.resolved(name: notificationCoordinator.personalizationStore.name)?.text ?? affirmation.text)
                .font(.body)
                .lineSpacing(3)
            if affirmation.resolved(name: notificationCoordinator.personalizationStore.name) == nil {
                Text("Add a name in Settings to use this affirmation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if affirmation.isBundled || !affirmation.tags.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if affirmation.isBundled {
                        Image(systemName: "lock.fill")
                            .accessibilityLabel("Read-only message")
                    }
                    if !affirmation.tags.isEmpty {
                        Text(affirmation.tags.map { $0.lowercased() }.joined(separator: " · "))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

    private var errorIsPresented: Binding<Bool> {
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
            AffirmationEditorView(affirmation: affirmation, availableTags: store.availableTags, name: notificationCoordinator.personalizationStore.name) { text, tags in
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

#if DEBUG
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
    libraryPreview(selection: .sources(favourites: false, tags: ["Example", "Another tag"]))
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Dark appearance") {
    libraryPreview()
        .environment(\.appTheme, .nature)
        .tint(AppTheme.nature.accentColor)
        .preferredColorScheme(.dark)
}

@MainActor
private func libraryPreview(
    affirmations: [Affirmation]? = nil,
    selection: AffirmationSelection = .all
) -> LibraryView {
    let store = AffirmationStore(affirmations: affirmations ?? PreviewContent.affirmations)
    let coordinator = NotificationCoordinator(
        affirmationStore: store,
        scheduleStore: ScheduleStore(),
        scheduler: PreviewNotificationScheduler()
    )
    return LibraryView(store: store, notificationCoordinator: coordinator, initialFilter: selection)
}
#endif
