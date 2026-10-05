import Dispatch
import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct NotificationSoundPreviewTests {
    @Test("Audio creation, playback and stopping run off the main thread in order")
    func playbackUsesBackgroundQueue() async {
        let queue = DispatchQueue(label: "SoundPreviewTests.playback")
        let preview = NotificationSoundPreview(queue: queue) { _ in
            #expect(!Thread.isMainThread)
            return PreviewPlayerSpy()
        }
        preview.play(.upliftingFlute) { _ in Issue.record("Unexpected preview error") }
        await drain(queue)
        preview.stop()
        await drain(queue)
    }

    @Test("Dismissing during audio preparation prevents late playback", .timeLimit(.minutes(1)))
    func cancelsPreparation() async {
        let queue = DispatchQueue(label: "SoundPreviewTests.cancellation")
        let release = DispatchSemaphore(value: 0)
        let started = AsyncStream<Void>.makeStream()
        let preview = NotificationSoundPreview(queue: queue) { _ in
            started.continuation.yield(())
            release.wait()
            return CancelledPreviewPlayer()
        }
        preview.play(.magicMarimba) { _ in Issue.record("Dismissed preview reported an error") }
        for await _ in started.stream { break }
        preview.stop()
        release.signal()
        await drain(queue)
        started.continuation.finish()
    }

    @Test("Preview failures are delivered on the main actor", .timeLimit(.minutes(1)))
    func reportsFailure() async {
        let errors = AsyncStream<Void>.makeStream()
        let preview = NotificationSoundPreview { _ in
            throw NotificationSchedulerTestError.failed
        }
        preview.play(.choirHarpBless) { _ in
            MainActor.assertIsolated()
            errors.continuation.yield(())
        }
        for await _ in errors.stream { break }
        errors.continuation.finish()
        preview.stop()
    }

    private func drain(_ queue: DispatchQueue) async {
        await withCheckedContinuation { continuation in
            queue.async { continuation.resume() }
        }
    }
}

private nonisolated final class PreviewPlayerSpy: SoundPreviewPlayer {
    private var didPlay = false

    func play() -> Bool {
        #expect(!Thread.isMainThread)
        #expect(!didPlay)
        didPlay = true
        return true
    }

    func stop() {
        #expect(!Thread.isMainThread)
        #expect(didPlay)
    }

    deinit {
        #expect(!Thread.isMainThread)
        #expect(didPlay)
    }
}

private nonisolated final class CancelledPreviewPlayer: SoundPreviewPlayer {
    func play() -> Bool {
        Issue.record("Cancelled preview started playing")
        return true
    }

    func stop() {}
}
