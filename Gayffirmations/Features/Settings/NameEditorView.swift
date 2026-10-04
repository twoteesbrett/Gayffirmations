import SwiftUI

struct NameEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let notificationCoordinator: NotificationCoordinator

    @State private var nameDraft: String
    @State private var errorMessage: String?
    @FocusState private var nameIsFocused: Bool

    init(notificationCoordinator: NotificationCoordinator) {
        self.notificationCoordinator = notificationCoordinator
        _nameDraft = State(initialValue: notificationCoordinator.personalizationStore.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (optional)", text: $nameDraft)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                        .focused($nameIsFocused)
                        .submitLabel(.done)
                        .onSubmit(save)
                        .accessibilityLabel("Name")
                } footer: {
                    Text("Used in personalised affirmations. Leave blank to skip personalised affirmations. Tap Done to save your changes.")
                }
            }
            .themedBackground()
            .navigationTitle("Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: save)
                        .disabled(notificationCoordinator.isUpdating)
                }
            }
            .onAppear { nameIsFocused = true }
            .alert("Unable to Save Name", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    private func save() {
        guard !notificationCoordinator.isUpdating else { return }
        do {
            let name = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if name != notificationCoordinator.personalizationStore.name {
                try notificationCoordinator.setName(name)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
