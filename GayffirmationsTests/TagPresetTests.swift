import Testing
@testable import Gayffirmations

struct TagPresetTests {
    @Test("Presets use existing tags, preserve spelling, and omit unavailable tags")
    func availablePresets() {
        let tags = TagPreset.tagChoices(from: ["Confidence", "confidence", "Work", "anxiety"])
        let presets = TagPreset.presets(for: tags)
        #expect(presets.map(\.name) == ["Feel Good", "Tough Days"])
        #expect(presets[0].tags == ["Confidence"])
        #expect(tags.contains("Work"))
        #expect(tags.count == 3)
    }

    @Test("Editor offers all predefined tags without replacing existing spelling")
    func editorChoices() {
        let tags = TagPreset.tagChoices(from: ["PRIDE", "Work"], includePredefined: true)
        #expect(tags.contains("PRIDE"))
        #expect(!tags.contains("pride"))
        #expect(tags.contains("playful"))
        #expect(tags.count == 25)
        #expect(TagPreset.presets(for: tags).count == 7)
    }

    @Test("Applying a preset replaces tags and preserves Favourites")
    func replacesTags() {
        let preset = TagPreset.predefined[0]
        let selection = preset.applying(to: .sources(favourites: true, tags: ["Work"]))
        #expect(selection.includesFavourites)
        #expect(selection.selectedTags == preset.tags)
        #expect(preset.matchesSelection(selection))
        #expect(!preset.matchesSelection(selection.selectingTag("joy", included: false)))
        #expect(!preset.matchesSelection(selection.selectingTag("Work", included: true)))
        #expect(preset.applying(to: .all).includesFavourites == false)
    }

    @Test("Preset recognition ignores case and tag order")
    func recognizesSelection() {
        #expect(TagPreset.predefined[0].matchesSelection(
            .sources(favourites: false, tags: ["JOY", "confidence", "self-worth"])
        ))
        #expect(TagPreset.presets(for: []).isEmpty)
    }
}
