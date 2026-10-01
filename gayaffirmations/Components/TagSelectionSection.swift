import SwiftUI

/// Shared controls; callers own persistence and empty-selection behavior.
struct TagSelectionSection: View {
    let tags: [String]
    let selection: AffirmationSelection
    let onChange: (AffirmationSelection) -> Void

    private var presets: [TagPreset] {
        TagPreset.presets(for: tags)
    }

    private var presetLabel: String {
        if selection.selectedTags.isEmpty { return "Choose a preset" }
        return presets.first { $0.matchesSelection(selection) }?.name ?? "Custom selection"
    }

    var body: some View {
        Section {
            Menu {
                Button("Clear all") {
                    onChange(.all)
                }
                if !presets.isEmpty {
                    Divider()
                    ForEach(presets) { preset in
                        Button(preset.name) {
                            onChange(preset.applying(to: selection))
                        }
                    }
                }
            } label: {
                LabeledContent("Presets") {
                    Text(presetLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityHint("Choose a preset or clear all selections")

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
            Text("A preset selects its available tags. You can then adjust individual tags.")
        }
    }
}

#Preview("Custom tags at largest text size") {
    Form {
        TagSelectionSection(
            tags: ["A long custom tag with no matching preset"],
            selection: .tag("A long custom tag with no matching preset")
        ) { _ in }
    }
    .environment(\.dynamicTypeSize, .accessibility5)
}
