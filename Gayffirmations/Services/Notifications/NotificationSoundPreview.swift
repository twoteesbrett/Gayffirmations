import AVFAudio
import Foundation

@MainActor
final class NotificationSoundPreview {
    private var player: AVAudioPlayer?

    func play(_ sound: NotificationSound) throws {
        stop()
        guard let filename = sound.filename else { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            throw PreviewError.unavailable
        }
        let player = try AVAudioPlayer(contentsOf: url)
        self.player = player
        guard player.play() else {
            stop()
            throw PreviewError.unavailable
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private enum PreviewError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            "This sound could not be previewed. Please try again."
        }
    }
}
