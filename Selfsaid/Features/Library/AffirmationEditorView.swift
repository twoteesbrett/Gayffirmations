import SwiftUI

struct AffirmationEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let affirmation: Affirmation?
    let availableTags: [String]
    let onSave: (String, [String]) throws -> Void

    @State private var text: String
    @State private var selectedTags: [String]
    @State private var newTag = ""
    @State private var validationMessage: String?
    @FocusState private var textFieldIsFocused: Bool
    @AccessibilityFocusState private var validationMessageIsFocused: Bool

    init(
        affirmation: Affirmation? = nil,
        availableTags: [String] = [],
        onSave: @escaping (String, [String]) throws -> Void
    ) {
        self.affirmation = affirmation
        self.availableTags = availableTags
        self.onSave = onSave
        _text = State(initialValue: affirmation?.text ?? "")
        _selectedTags = State(initialValue: affirmation?.tags ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Affirmation") {
                    TextField(
                        "I am...",
                        text: $text,
                        axis: .vertical
                    )
                    .lineLimit(3...8)
                    .focused($textFieldIsFocused)
                    .accessibilityLabel("Affirmation text")

                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(validationMessage)")
                            .accessibilityFocused($validationMessageIsFocused)
                    }
                }
                tagSection
            }
            .navigationTitle(affirmation == nil ? "New Affirmation" : "Edit Affirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .onAppear {
                textFieldIsFocused = true
            }
        }
    }

    private var tagChoices: [String] {
        Array(Set(availableTags + selectedTags))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private var tagSection: some View {
        Section {
            ForEach(tagChoices, id: \.self) { tag in
                Toggle(tag, isOn: Binding(
                    get: { selectedTags.contains(tag) },
                    set: { isSelected in
                        if isSelected {
                            selectedTags.append(tag)
                        } else {
                            selectedTags.removeAll { $0 == tag }
                        }
                    }
                ))
            }
            HStack {
                TextField("New tag", text: $newTag)
                    .submitLabel(.done)
                    .onSubmit(addTag)
                Button("Add", action: addTag)
                    .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            Text("Tags")
        } footer: {
            Text("Choose existing tags or add your own. Tags are optional.")
        }
    }

    private func addTag() {
        let name = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let tag = tagChoices.first {
            $0.compare(name, options: .caseInsensitive) == .orderedSame
        } ?? name
        if !selectedTags.contains(tag) {
            selectedTags.append(tag)
        }
        newTag = ""
    }

    private func save() {
        do {
            addTag()
            try onSave(text, selectedTags)
            dismiss()
        } catch {
            validationMessage = error.localizedDescription
            validationMessageIsFocused = true
        }
    }
}

#Preview("Tag editor") {
    AffirmationEditorView(
        affirmation: Affirmation(text: "My effort matters.", tags: ["Work"]),
        availableTags: ["Calm", "Confidence", "Work"]
    ) { _, _ in }
}
