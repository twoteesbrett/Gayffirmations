import SwiftUI

struct AffirmationEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let affirmation: Affirmation?
    let onSave: (String) throws -> Void

    @State private var text: String
    @State private var validationMessage: String?
    @FocusState private var textFieldIsFocused: Bool
    @AccessibilityFocusState private var validationMessageIsFocused: Bool

    init(
        affirmation: Affirmation? = nil,
        onSave: @escaping (String) throws -> Void
    ) {
        self.affirmation = affirmation
        self.onSave = onSave
        _text = State(initialValue: affirmation?.text ?? "")
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

    private func save() {
        do {
            try onSave(text)
            dismiss()
        } catch {
            validationMessage = error.localizedDescription
            validationMessageIsFocused = true
        }
    }
}
