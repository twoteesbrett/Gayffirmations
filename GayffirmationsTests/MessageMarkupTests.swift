import Foundation
import Testing
@testable import Gayffirmations

struct MessageMarkupTests {
    @Test @MainActor func historicalInvisibleContentIsPreservedButNotDisplayedOrDelivered() throws {
        let suite = "MessageMarkupTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let blank = Affirmation(text: "<small></small>")
        let visible = Affirmation(text: "<small>Hello</small><br>World")
        try repository.saveAffirmations([blank, visible])
        let bytes = defaults.data(forKey: "gayffirmations.affirmations")
        let store = AffirmationStore(repository: repository, defaultAffirmations: [])
        #expect(store.persistenceErrorMessage == nil)
        #expect(store.affirmations == [blank, visible])
        #expect(defaults.data(forKey: "gayffirmations.affirmations") == bytes)

        for enabled in [false, true] {
            let schedules = [AffirmationSchedule(isEnabled: enabled)]
            let context = TodayAffirmationResolver().context(
                at: .now, schedules: schedules, affirmations: store.affirmations,
                fallbackSelection: .all, name: ""
            )
            #expect(context.affirmation == visible)
            #expect(context.browsingAffirmations == [visible])
            let emptyContext = TodayAffirmationResolver().context(
                at: .now, schedules: schedules, affirmations: [blank],
                fallbackSelection: .all, name: ""
            )
            #expect(emptyContext.affirmation == nil)
            #expect(emptyContext.browsingAffirmations.isEmpty)
        }
        let schedule = AffirmationSchedule(isEnabled: true)
        let plan = try NotificationPlanner().plan(for: [schedule], affirmations: store.affirmations, name: "")
        #expect(plan.count == schedule.notificationsPerDay)
        #expect(plan.allSatisfy { $0.reminder.affirmationText == "Hello\nWorld" })
        #expect(try NotificationPlanner().plan(for: [schedule], affirmations: [blank], name: "").isEmpty)
        #expect(Affirmation(text: "{name}").resolved(name: "<br>") == nil)
        try store.update(id: blank.id, text: "Repaired")
        #expect(try repository.loadAffirmations()?.first?.text == "Repaired")
    }

    @Test func parsesSmallRunsAndPreservesLineBreaks() {
        let markup = MessageMarkup("<small>Let it go means to</small>\nLet it be")
        #expect(markup.runs.count == 2)
        #expect(markup.runs[0].style == .small)
        #expect(markup.runs[1].style == .normal)
        #expect(markup.plainText == "Let it go means to\nLet it be")
        #expect(MessageMarkup("A<small>B</small>C<small>D</small>").plainText == "ABCD")
    }

    @Test(arguments: ["<small>unfinished", "stray</small>", "<small>a<small>b</small></small>", "<b>literal</b>", "<small size=2>literal</small>", "2 < 3 & 4 > 1"])
    func unsupportedOrMalformedMarkupStaysLiteral(_ source: String) {
        #expect(MessageMarkup(source).plainText == source)
        #expect(MessageMarkup(source).runs.allSatisfy { $0.style == .normal })
    }

    @Test(arguments: ["<br>", "<br/>", "<br />"])
    func breakTagsProduceNewlines(_ tag: String) {
        #expect(MessageMarkup("First\(tag)Second\(tag)\(tag)Third").plainText == "First\nSecond\n\nThird")
        #expect(MessageMarkup("\(tag)Text\(tag)").plainText == "\nText\n")
        let markup = MessageMarkup("<small>Let it go\(tag)means to</small>\(tag)Let it be")
        #expect(markup.plainText == "Let it go\nmeans to\nLet it be")
        #expect(markup.runs[0].style == .small)
        #expect(markup.runs[1].style == .small)
        #expect(markup.runs.last?.style == .normal)
        #expect(MessageMarkup("<br class=foo>").plainText == "<br class=foo>")
    }

    @Test func sourceAndPersonalizationArePreserved() {
        let source = Affirmation(text: "<small>Hello, {name}</small>\nYou belong.")
        #expect(MessageMarkup(source.resolved(name: "Alex")!.text).plainText == "Hello, Alex\nYou belong.")
        #expect(source.text == "<small>Hello, {name}</small>\nYou belong.")
    }
}
