import Testing
@testable import Gayffirmations

struct TagChoicesTests {
    @Test("Tag choices preserve first spelling, remove duplicates, and sort naturally")
    func sortedUniqueTags() {
        let tags = TagChoices.sortedUnique(["Work 10", "Confidence", "confidence", "Work 2", "anxiety"])
        #expect(tags == ["anxiety", "Confidence", "Work 2", "Work 10"])
    }

    @Test("Empty tags produce no choices")
    func emptyTags() {
        #expect(TagChoices.sortedUnique([]).isEmpty)
    }
}
