import SwiftUI

struct NotificationSoundPickerView: View {
    @Environment(\.scenePhase) private var scenePhase
    let store: ScheduleStore
    let notificationCoordinator: NotificationCoordinator

    @State private var preview = NotificationSoundPreview()
    @State private var isSaving = false
    @State private var errorMessage: String?

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
                                .opacity(store.schedule.sound == sound ? 1 : 0)
                                .accessibilityHidden(true)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(store.schedule.sound == sound ? .isSelected : [])
                    .accessibilityHint(sound.filename != nil
                        ? "Selects and plays this sound" : "Selects this notification sound")
                }
            } footer: {
                Text("None delivers reminders silently. Default uses your iPhone’s notification sound. Tap a custom sound to select and hear it. Silent mode and your notification settings can silence sounds.")
            }
        }
        .themedBackground()
        .navigationTitle("Sound")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isSaving || notificationCoordinator.isUpdating)
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
        guard !isSaving, !notificationCoordinator.isUpdating else { return }
        // Preview immediately so a delayed save cannot start audio after dismissal.
        // Default and None stop the previous preview without playing an asset.
        preview.play(sound) { error in
            errorMessage = error.localizedDescription
        }
        guard sound != store.schedule.sound else { return }
        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            do {
                try await notificationCoordinator.setSound(sound)
            } catch {
                preview.stop()
                errorMessage = error.localizedDescription
            }
        }
    }
}
