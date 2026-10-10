import Foundation

/// Advance only when the displayed affirmation changes, never on a view refresh.
struct AffirmationImageRotation {
    private(set) var affirmationID: UUID?
    private(set) var imageIndex = 0

    mutating func update(affirmationID: UUID?, imageCount: Int, direction: Int = 1) {
        guard let affirmationID else { return }
        guard self.affirmationID != affirmationID else { return }
        if self.affirmationID != nil, imageCount > 0 {
            imageIndex = ((imageIndex + direction) % imageCount + imageCount) % imageCount
        }
        self.affirmationID = affirmationID
    }
}
