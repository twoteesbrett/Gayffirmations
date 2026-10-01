import Foundation
import Testing
@testable import Selfsaid

struct AffirmationPhotoTests {
    @Test("Photo selection prefers a selected tag belonging to the affirmation")
    func selectedTagPreference() {
        let affirmation = Affirmation(text: "Example", tags: ["confidence", "self-worth"])
        #expect(AffirmationPhoto.resolve(
            for: affirmation, selectedTags: ["playful", "SELF-WORTH"]
        ) == .selfWorth)
    }

    @Test("Mixed tags have a consistent fallback regardless of their order")
    func fallbackPriority() {
        for tags in [["confidence", "playful"], ["playful", "confidence"]] {
            let affirmation = Affirmation(text: "Example", tags: tags)
            #expect(AffirmationPhoto.resolve(for: affirmation, selectedTags: []) == .playful)
        }
    }

    @Test("Missing photos retain the theme background")
    func missingPhoto() {
        #expect(AffirmationPhoto.resolve(for: nil, selectedTags: ["playful"]) == nil)
        #expect(AffirmationPhoto.resolve(
            for: Affirmation(text: "Example", tags: ["custom"]), selectedTags: ["confidence"]
        ) == nil)
    }
}
