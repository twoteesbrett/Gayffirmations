import SwiftUI

struct AffirmationEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let affirmation: Affirmation?
    let onSave: (String) throws -> Void

    @State private var text: String
    @State private var validationMessage: String?

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

                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundStyle(.red)
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
        }
    }

    private func save() {
        do {
            try onSave(text)
            dismiss()
        } catch {
            validationMessage = error.localizedDescription
        }
    }
}
