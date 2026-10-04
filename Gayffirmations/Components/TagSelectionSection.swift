import SwiftUI

/// Shared controls; callers own persistence and empty-selection behavior.
struct TagSelectionSection: View {
    let tags: [String]
    let selection: AffirmationSelection
    let onChange: (AffirmationSelection) -> Void

    var body: some View {
        Section {
            Button("Clear tags") {
                onChange(.sources(favourites: selection.includesFavourites, tags: []))
            }
            .disabled(selection.selectedTags.isEmpty)

            ForEach(tags, id: \.self) { tag in
                Toggle(isOn: Binding(
                    get: { selection.containsTag(tag) },
                    set: { onChange(selection.selectingTag(tag, included: $0)) }
                )) {
                    Text(AffirmationTag(rawValue: tag)?.name ?? tag.lowercased())
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

        } header: {
            Text("Tags")
        }
    }
}

#Preview("Custom tags at largest text size") {
    Form {
        TagSelectionSection(
            tags: ["A long custom tag"],
            selection: .tag("A long custom tag")
        ) { _ in }
    }
    .environment(\.dynamicTypeSize, .accessibility5)
}
