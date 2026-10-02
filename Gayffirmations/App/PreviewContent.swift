#if DEBUG
import Foundation

/// UI fixtures only; these entries are never loaded into the saved library.
enum PreviewContent {
    static let affirmations = [
        Affirmation(text: "An example affirmation.", isFavorite: true, tags: ["Example"]),
        Affirmation(text: "A longer example affirmation to check wrapping and accessibility layouts.", tags: ["Another tag"])
    ]
}
#endif
