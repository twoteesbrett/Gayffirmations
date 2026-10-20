import Foundation
import Testing
@testable import Gayffirmations

struct CatalogueMigrationTests {
    private func legacy(text: String, tags: [String], suffix: String = "001") throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "id": "B7E77000-0000-4000-8000-000000000\(suffix)",
            "text": text, "tags": tags, "isFavorite": true
        ])
    }

    @Test func oldAndRetiredOriginalsRemainBundled() throws {
        let originals: [(String, String, [String])] = [
            ("001", "“I'm full. The pantry doesn't need a follow-up visit.", ["food"]),
            ("039", "Take up space, honey. You didn't come this far to apologise for existing.", ["confidence", "body"]),
            ("065", "Enjoy it, honey. You chose a treat, not a fucking tribunal.", ["treat-yourself"])
        ]
        for (suffix, text, tags) in originals {
            let entry = try JSONDecoder().decode(Affirmation.self, from: legacy(text: text, tags: tags, suffix: suffix))
            #expect(entry.isBundled)
            #expect(entry.isFavorite)
        }
    }

    @Test func legacyPersonalEditsKeepOwnership() throws {
        let changedText = try JSONDecoder().decode(Affirmation.self, from: legacy(text: "My personal rewrite", tags: ["food"]))
        let changedTags = try JSONDecoder().decode(Affirmation.self, from: legacy(text: "“I'm full. The pantry doesn't need a follow-up visit.", tags: ["Mine"]))
        #expect(changedText.source == .user)
        #expect(changedTags.source == .user)
    }

    @Test func duplicateSavedTagsFailBeforeMigration() throws {
        for tags in [["Mine", "Mine"], ["Mine", "mine"], ["confidence", "confidence"]] {
            let data = try legacy(text: "Personal", tags: tags)
            #expect(throws: AffirmationValidationError.invalidTags) {
                try JSONDecoder().decode(Affirmation.self, from: data)
            }
        }
        let merged = try JSONDecoder().decode(Affirmation.self, from: legacy(text: "Personal", tags: ["confidence", "body"]))
        #expect(merged.tags == ["human"])
    }

    @Test func roleModelCategoryHasTenUniqueBundledMessages() throws {
        let entries = Affirmation.starterAffirmations.filter { $0.tags.contains("role-model") }
        #expect(entries.count == 10)
        #expect(entries.allSatisfy { $0.isBundled && $0.tags == ["role-model"] })
        #expect(AffirmationTag.roleModel.name == "Role Model")
        #expect(AffirmationTag.roleModel.displayName == "Be the Man You Needed")
        #expect(entries.first?.text == "Be the gay man you needed when you were younger.")
        #expect(entries.last?.text == "Let your kindness do the talking.")
        #expect(Set(Affirmation.starterAffirmations.map(\.id)).count == 50)
        try AffirmationValidation.validate(Affirmation.starterAffirmations)
    }

    @Test func newHumanMessageDoesNotReuseRetiredTreatIdentity() throws {
        let entry = try #require(Affirmation.starterAffirmations.first { $0.id == UUID(uuidString: "B7E77000-0000-4000-8000-000000000075") })
        #expect(entry.id == UUID(uuidString: "B7E77000-0000-4000-8000-000000000075"))
        #expect(!Affirmation.starterAffirmations.contains { $0.id == UUID(uuidString: "B7E77000-0000-4000-8000-000000000065") })
    }
}
