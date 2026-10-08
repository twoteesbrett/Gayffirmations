import SwiftUI

struct NotificationSoundPickerView: View {
    @Environment(\.scenePhase) private var scenePhase
    let coordinator: NotificationCoordinator
    private var selection: NotificationSound { coordinator.scheduleStore.notificationSound }

    @State private var preview = NotificationSoundPreview()
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                ForEach(NotificationSound.allCases) { sound in
                    Button {
                        select(sound)
                    } label: {
                        HStack(spacing: 12) {
                            Text(sound.title)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .opacity(selection == sound ? 1 : 0)
                                .accessibilityHidden(true)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == sound ? .isSelected : [])
                    .accessibilityHint(sound.filename != nil
                        ? "Selects and plays this sound" : "Selects this notification sound")
                }
            } footer: {
                Text("This sound applies to all schedules. None delivers reminders silently. Default uses your iPhone’s notification sound. Tap a custom sound to select and hear it. Silent mode and your notification settings can silence sounds.")
            }
        }
        .themedBackground()
        .disabled(isSaving || coordinator.isUpdating)
        .navigationTitle("Sound")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { preview.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { preview.stop() }
        }
        .alert("Unable to Use Sound", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func select(_ sound: NotificationSound) {
        // Preview immediately so a delayed save cannot start audio after dismissal.
        // Default and None stop the previous preview without playing an asset.
        preview.play(sound) { error in
            errorMessage = error.localizedDescription
        }
        isSaving = true
        Task {
            defer { isSaving = false }
            do { try await coordinator.setSound(sound) }
            catch { errorMessage = error.localizedDescription }
        }
    }
}
