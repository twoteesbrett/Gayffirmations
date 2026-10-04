import Foundation

/// Visibility policy only. The view owns the cancellable timer and animation.
struct TodayControlsState {
    private(set) var isVisible = false
    private(set) var hideDeadline: Date?
    private var alwaysVisible = false

    mutating func show(at now: Date = .now) {
        isVisible = true
        hideDeadline = alwaysVisible ? nil : now.addingTimeInterval(5)
    }

    mutating func toggle(at now: Date = .now) {
        guard !alwaysVisible else { return }
        isVisible.toggle()
        hideDeadline = isVisible ? now.addingTimeInterval(5) : nil
    }

    mutating func registerInteraction(at now: Date = .now) {
        guard isVisible, !alwaysVisible else { return }
        hideDeadline = now.addingTimeInterval(5)
    }

    mutating func reset() {
        isVisible = alwaysVisible
        hideDeadline = nil
    }

    mutating func setAlwaysVisible(_ enabled: Bool) {
        alwaysVisible = enabled
        reset()
    }

    mutating func expire(deadline: Date, at now: Date = .now) {
        guard hideDeadline == deadline, now >= deadline else { return }
        reset()
    }
}
