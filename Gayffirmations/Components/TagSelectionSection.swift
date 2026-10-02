import SwiftUI

/// Shared controls; callers own persistence and empty-selection behavior.
struct TagSelectionSection: View {
    let tags: [String]
    let selection: AffirmationSelection
    let onChange: (AffirmationSelection) -> Void

    var body: some View {
        Section {
            Button("Clear all selections") {
                onChange(.all)
            }

            ForEach(tags, id: \.self) { tag in
                Toggle(isOn: Binding(
                    get: { selection.containsTag(tag) },
                    set: { onChange(selection.selectingTag(tag, included: $0)) }
                )) {
                    Text(tag.lowercased())
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button("Clear tags") {
                onChange(.sources(favourites: selection.includesFavourites, tags: []))
            }
            .disabled(selection.selectedTags.isEmpty)
        } header: {
            Text("Tags")
        } footer: {
            Text("Choose tags to include matching affirmations.")
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
