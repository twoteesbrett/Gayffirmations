import Testing
@testable import Gayffirmations

struct TagChoicesTests {
    @Test("Tag choices preserve first spelling, remove duplicates, and sort naturally")
    func sortedUniqueTags() {
        let tags = TagChoices.sortedUnique(["Work 10", "Travel", "travel", "Work 2", "anxiety"])
        #expect(tags == ["anxiety", "Travel", "Work 2", "Work 10"])
    }

    @Test("Categories sort by their visible names")
    func categoriesSortByVisibleName() {
        let tags = TagChoices.sortedUnique(AffirmationTag.allCases.map(\.rawValue))
        #expect(tags == ["critic", "inner-cynic", "food", "gay", "human", "role-model"])
    }

    @Test("Retired categories merge without breaking saved selections")
    func retiredCategories() {
        #expect(TagChoices.sortedUnique(["body", "confidence", "self-kindness", "inner-critic", "food"]) == ["critic", "food", "human"])
        let entry = Affirmation(text: "Example", tags: ["body", "confidence"])
        #expect(entry.tags == ["human"])
        #expect(AffirmationSelection.tag("confidence").matchingAffirmations(in: [entry]) == [entry])
        #expect(AffirmationSelection.sources(favourites: false, tags: ["body", "self-kindness"]).selectedTags == ["human"])
        #expect(AffirmationTag.critic.displayName == "The Itty Bitty Shitty Committee")
    }

    @Test("Empty tags produce no choices")
    func emptyTags() {
        #expect(TagChoices.sortedUnique([]).isEmpty)
    }
}
