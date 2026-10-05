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
                    HStack(spacing: 12) {
                        Button {
                            select(sound)
                        } label: {
                            HStack {
                                Text(sound.title)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                if store.schedule.sound == sound {
                                    Image(systemName: "checkmark")
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(store.schedule.sound == sound ? .isSelected : [])

                        if sound.filename != nil {
                            Button {
                                do {
                                    try preview.play(sound)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            } label: {
                                Image(systemName: "play.circle")
                                    .font(.title2)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Preview \(sound.title)")
                            .accessibilityHint("Plays the sound without changing your selection")
                        }
                    }
                }
            } footer: {
                Text("Default uses your iPhone’s notification sound. None delivers reminders silently. Use the play buttons to preview custom sounds. Silent mode and your notification settings can silence sounds.")
            }
        }
        .themedBackground()
        .navigationTitle("Notification Sound")
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
        preview.stop()
        guard !isSaving, !notificationCoordinator.isUpdating,
              sound != store.schedule.sound else { return }
        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            do {
                try await notificationCoordinator.setSound(sound)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
