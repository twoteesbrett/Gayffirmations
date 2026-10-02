import Testing
@testable import Gayffirmations

struct TagPresetTests {
    @Test("Tag choices preserve spelling, remove duplicates, and keep custom tags")
    func availableTags() {
        let tags = TagPreset.tagChoices(from: ["Confidence", "confidence", "Work", "anxiety"])
        #expect(tags.count == 3)
        #expect(tags.contains("Confidence"))
        #expect(tags.contains("Work"))
        #expect(TagPreset.presets(for: tags).isEmpty)
    }

    @Test("The editor introduces no retired starter tags")
    func editorChoices() {
        let tags = TagPreset.tagChoices(from: ["PRIDE", "Work"], includePredefined: true)
        #expect(tags == ["PRIDE", "Work"])
    }

    @Test("Applying a preset replaces tags and preserves Favourites")
    func replacesTags() {
        let preset = TagPreset(name: "Example", tags: ["Confidence", "Joy"])
        let selection = preset.applying(to: .sources(favourites: true, tags: ["Work"]))
        #expect(selection.includesFavourites)
        #expect(selection.selectedTags == preset.tags)
        #expect(preset.matchesSelection(selection))
        #expect(!preset.matchesSelection(selection.selectingTag("Joy", included: false)))
        #expect(!preset.matchesSelection(selection.selectingTag("Work", included: true)))
        #expect(preset.applying(to: .all).includesFavourites == false)
    }

    @Test("Preset recognition ignores case and tag order")
    func recognizesSelection() {
        let preset = TagPreset(name: "Example", tags: ["Confidence", "Joy"])
        #expect(preset.matchesSelection(.sources(favourites: false, tags: ["JOY", "confidence"])))
        #expect(TagPreset.presets(for: []).isEmpty)
    }
}
