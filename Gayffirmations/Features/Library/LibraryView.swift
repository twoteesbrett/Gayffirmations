import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    let store: AffirmationStore
    let notificationCoordinator: NotificationCoordinator

    @Environment(\.appTheme) private var appTheme

    @State private var editorDestination: EditorDestination?
    @State private var persistenceErrorMessage: String?
    @State private var isTagPickerPresented = false
    @State private var sourceFilter: Affirmation.Source?

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
                            Text(sourceFilter == .user ? "Add your own affirmation or clear filters to see more entries." : sourceFilter == .bundled ? "Clear filters or restore default affirmations in Settings to see bundled messages." : filter.emptyMessage)
                        } actions: {
                            Button("Show All Affirmations") {
                                clearFilters()
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        affirmationList
                    }
                } footer: {
                    if !filteredAffirmations.isEmpty {
                        Text("Tap an affirmation to edit, swipe right to edit, or left to delete.")
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

            if filter != .all || sourceFilter != nil {
                HStack(alignment: .firstTextBaseline) {
                    Text(activeFilterName)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button("Clear filters") { clearFilters() }
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
            filterButton("All", systemImage: "square.stack", isSelected: filter == .all && sourceFilter == nil) {
                clearFilters()
            }
            filterButton("Bundled", systemImage: "shippingbox", isSelected: sourceFilter == .bundled) {
                sourceFilter = sourceFilter == .bundled ? nil : .bundled
            }
            filterButton("Mine", systemImage: "person", isSelected: sourceFilter == .user) {
                sourceFilter = sourceFilter == .user ? nil : .user
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
                    Text("Show entries matching any selected tag or Favourites. Mine shows your own affirmations; Bundled shows messages included with the app. These filters only change the Library list.")
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

    private func clearFilters() {
        filter = .all
        sourceFilter = nil
    }

    private var activeFilterName: String {
        guard let sourceFilter else { return filter.name }
        let sourceName = sourceFilter == .user ? "Mine" : "Bundled"
        return filter == .all ? sourceName : "\(sourceName) · \(filter.name)"
    }

    private var hasSelectedTags: Bool {
        !filter.selectedTags.isEmpty
    }

    private var filteredAffirmations: [Affirmation] {
        let matches = filter.matchingAffirmations(in: store.affirmations)
        return sourceFilter.map { source in matches.filter { $0.source == source } } ?? matches
    }

    private var affirmationList: some View {
        ForEach(filteredAffirmations) { affirmation in
            HStack(spacing: 12) {
                Button {
                    editorDestination = .edit(affirmation)
                } label: {
                    affirmationLabel(affirmation)
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
                .tint(appTheme.accentColor)
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    performPersistedChange {
                        try store.delete(id: affirmation.id)
                    }
                }
                .tint(.red)
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
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: affirmation.isBundled ? "shippingbox" : "person")
                    .accessibilityLabel(affirmation.isBundled ? "Bundled affirmation" : "Your affirmation")
                if !affirmation.tags.isEmpty {
                    Text(affirmation.tags.map { $0.lowercased() }.joined(separator: " · "))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
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
            AffirmationEditorView(affirmation: affirmation, availableTags: store.availableTags, name: notificationCoordinator.personalizationStore.name, onRestore: store.defaultAffirmations.contains(where: { $0.id == affirmation.id }) ? {
                try store.restoreOriginal(id: affirmation.id)
            } : nil) { text, tags in
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
        .environment(\.appTheme, .eden)
        .tint(AppTheme.eden.accentColor)
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
