import AVFAudio
import Dispatch
import Foundation

@MainActor
final class NotificationSoundPreview {
    private let queue: DispatchQueue
    private let playback: SoundPreviewPlayback
    private var pendingWork: DispatchWorkItem?
    private var pendingRequest: SoundPreviewRequest?
    private var requestID: UUID?

    init(
        queue: DispatchQueue = DispatchQueue(label: "gayffirmations.sound-preview", qos: .userInitiated),
        makePlayer: @escaping @Sendable (URL) throws -> any SoundPreviewPlayer = {
            try AVAudioPlayer(contentsOf: $0)
        }
    ) {
        self.queue = queue
        playback = SoundPreviewPlayback(makePlayer: makePlayer)
    }

    func play(_ sound: NotificationSound, onError: @escaping @MainActor (Error) -> Void) {
        stop()
        guard let filename = sound.filename else { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            onError(SoundPreviewError.unavailable)
            return
        }
        let id = UUID()
        requestID = id
        let request = SoundPreviewRequest()
        pendingRequest = request
        let work = DispatchWorkItem { [playback, weak self] in
            do {
                try playback.play(url, request: request)
            } catch {
                Task { @MainActor [weak self] in
                    guard let self, self.requestID == id else { return }
                    onError(error)
                }
            }
        }
        pendingWork = work
        queue.async(execute: work)
    }

    func stop() {
        requestID = nil
        pendingRequest?.cancel()
        pendingRequest = nil
        pendingWork?.cancel()
        pendingWork = nil
        queue.async { [playback] in playback.stop() }
    }
}

nonisolated protocol SoundPreviewPlayer: AnyObject {
    func play() -> Bool
    func stop()
}

extension AVAudioPlayer: SoundPreviewPlayer {}

// All player creation, access, and release are confined to the preview's serial
// queue. AVAudioPlayer never crosses back to the main actor.
private nonisolated final class SoundPreviewPlayback: @unchecked Sendable {
    private var player: (any SoundPreviewPlayer)?
    private let makePlayer: @Sendable (URL) throws -> any SoundPreviewPlayer

    init(makePlayer: @escaping @Sendable (URL) throws -> any SoundPreviewPlayer) {
        self.makePlayer = makePlayer
    }

    func play(_ url: URL, request: SoundPreviewRequest) throws {
        stop()
        guard !request.isCancelled else { return }
        let player = try makePlayer(url)
        guard !request.isCancelled else { return }
        self.player = player
        guard player.play() else {
            stop()
            throw SoundPreviewError.unavailable
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}

// Cancellation can arrive on the main actor while audio preparation is running.
private nonisolated final class SoundPreviewRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.withLock { cancelled }
    }

    func cancel() {
        lock.withLock { cancelled = true }
    }
}

private nonisolated enum SoundPreviewError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "This sound could not be previewed. Please try again."
    }
}
