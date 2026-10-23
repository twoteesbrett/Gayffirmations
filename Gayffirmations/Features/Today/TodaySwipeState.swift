import SwiftUI

/// A drag's frozen content and settlement policy. The view owns animation and commit.
struct TodaySwipeState {
    struct Preview {
        let current: Affirmation
        let next: Affirmation
        let browsingState: TodayBrowsingState
        let direction: Int
        let width: CGFloat
        let currentImage: ThemeImage?
        let nextImage: ThemeImage?
    }

    var preview: Preview?
    var translation: CGFloat = 0
    var isSettling = false

    var progress: Double {
        guard let preview else { return 0 }
        return Double(min(1, abs(translation) / preview.width))
    }

    func shouldCommit(translation: CGFloat, velocity: CGFloat, cancelled: Bool) -> Bool {
        guard let preview, !cancelled else { return false }
        // Project a short distance ahead so a quick flick can complete a small drag.
        let projectedDistance = -(translation + velocity * 0.18) * CGFloat(preview.direction)
        return projectedDistance > preview.width * 0.3
    }

    mutating func reset() {
        preview = nil
        translation = 0
        isSettling = false
    }
}
