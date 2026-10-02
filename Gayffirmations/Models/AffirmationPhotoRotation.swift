import Foundation

/// Advance only when the displayed affirmation changes, never on a view refresh.
struct AffirmationPhotoRotation {
    private(set) var affirmationID: UUID?
    private(set) var photoIndex = 0

    mutating func update(affirmationID: UUID?, photoCount: Int, direction: Int = 1) {
        guard let affirmationID else { return }
        guard self.affirmationID != affirmationID else { return }
        if self.affirmationID != nil, photoCount > 0 {
            photoIndex = ((photoIndex + direction) % photoCount + photoCount) % photoCount
        }
        self.affirmationID = affirmationID
    }
}
