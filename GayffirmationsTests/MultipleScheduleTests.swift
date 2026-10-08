import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct MultipleScheduleTests {
    private let body = Affirmation(text: "Body", tags: ["Body", "Confidence"])
    private let confidence = Affirmation(text: "Confidence", tags: ["Confidence"])
    private let food = Affirmation(text: "Food", tags: ["Food"])
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    private func date(day: Int = 1, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }
    private func morning() -> AffirmationSchedule {
        AffirmationSchedule(name: "Morning", selection: .sources(favourites: false, tags: ["Body", "Confidence"]),
                            isEnabled: true, startTime: TimeOfDay(hour: 7, minute: 0),
                            endTime: TimeOfDay(hour: 9, minute: 0), notificationsPerDay: 2,
                            sound: .none, rhythm: .moreEarly, emphasis: .gentle)
    }
    private func evening() -> AffirmationSchedule {
        AffirmationSchedule(name: "Evening", selection: .tag("Food"), isEnabled: true,
                            startTime: TimeOfDay(hour: 18, minute: 0), endTime: TimeOfDay(hour: 20, minute: 0),
                            notificationsPerDay: 2, rhythm: .moreLate, emphasis: .strong)
    }

    @Test func unnamedSchedulesSaveReloadAndDeliver() async throws {
        let suite = "UnnamedSchedules.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let schedule = AffirmationSchedule(selection: .tag("Body"), isEnabled: true)
        #expect(schedule.name.isEmpty)
        let store = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(affirmationStore: AffirmationStore(affirmations: [body]),
                                                  scheduleStore: store, scheduler: scheduler)
        try await coordinator.saveSchedule(schedule)
        let restarted = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        #expect(restarted.persistenceErrorMessage == nil)
        #expect(restarted.schedules.contains(schedule))
        #expect(scheduler.scheduledReminders.count == schedule.notificationsPerDay)
        #expect(schedule.summary.contains(schedule.selection.name))
        #expect(schedule.summary.contains(schedule.timeRangeDescription))
    }

    @Test func separateTagsRhythmsAndStableIdentifiersWithOneSound() throws {
        let morning = morning(), evening = evening()
        let planner = NotificationPlanner()
        let plan = try planner.plan(for: [evening, morning], affirmations: [body, confidence, food], name: "", sound: .none)
        #expect(plan.map(\.affirmation.text) == ["Body", "Confidence", "Food", "Food"])
        #expect(plan.prefix(2).map(\.time) == (try ScheduleCalculator().notificationTimes(for: morning)))
        #expect(plan.suffix(2).map(\.time) == (try ScheduleCalculator().notificationTimes(for: evening)))
        #expect(plan.allSatisfy { $0.sound == .none })
        #expect(Set(plan.map(\.id)).count == 4)
        let eveningOnly = try planner.plan(for: [evening], affirmations: [food], name: "")
        #expect(eveningOnly.map(\.id) == plan.suffix(2).map(\.id))
    }

    @Test func todayUsesCombinedPlanAndBrowsesCurrentSource() throws {
        let schedules = [morning(), evening()]
        let entries = [body, confidence, food]
        let resolver = TodayAffirmationResolver()
        let plan = try NotificationPlanner().plan(for: schedules, affirmations: entries, name: "")
        for slot in plan {
            let context = resolver.context(at: slot.time.date(on: date(hour: 0), calendar: calendar),
                                           schedules: schedules, affirmations: entries,
                                           fallbackSelection: .all, name: "", calendar: calendar)
            #expect(context.affirmation == slot.affirmation)
            #expect(context.browsingAffirmations == (slot.scheduleID == schedules[0].id ? [body, confidence] : [food]))
        }
        let overnight = resolver.context(at: date(day: 2, hour: 5), schedules: schedules, affirmations: entries,
                                         fallbackSelection: .all, name: "", calendar: calendar)
        #expect(overnight.affirmation == food)
        #expect(overnight.nextChange == plan[0].time.date(on: date(day: 2, hour: 0), calendar: calendar))
        let now = date(hour: 12)
        let context = resolver.context(at: now, schedules: schedules, affirmations: entries,
                                       fallbackSelection: .all, name: "", calendar: calendar)
        var browsing = TodayBrowsingState()
        #expect(browsing.cycle(by: 1, at: now, context: context) == body)
        let next = resolver.context(at: context.nextChange, schedules: schedules, affirmations: entries,
                                    fallbackSelection: .all, name: "", calendar: calendar)
        #expect(browsing.affirmation(at: context.nextChange, context: next) == food)
    }

    @Test func overlappingSlotsAreKeptWithDeterministicTodayChoice() throws {
        let first = AffirmationSchedule(selection: .tag("Body"), isEnabled: true, notificationsPerDay: 1)
        let second = AffirmationSchedule(selection: .tag("Food"), isEnabled: true, notificationsPerDay: 1)
        let schedules = [first, second]
        let plan = try NotificationPlanner().plan(for: schedules, affirmations: [body, food], name: "")
        #expect(plan.count == 2)
        #expect(plan[0].time == plan[1].time)
        #expect(plan[0].id != plan[1].id)
        let context = TodayAffirmationResolver().context(at: date(hour: 13), schedules: schedules,
                                                       affirmations: [body, food], fallbackSelection: .all,
                                                       name: "", calendar: calendar)
        #expect(context.affirmation == food)
    }

    @Test func emptySchedulesPauseIndividuallyAndResume() async throws {
        let morning = morning(), evening = evening()
        let library = AffirmationStore(affirmations: [food])
        let store = ScheduleStore(schedule: morning)
        try store.replace(with: [morning, evening])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(affirmationStore: library, scheduleStore: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        #expect(coordinator.isPaused(morning))
        #expect(!coordinator.isPaused(evening))
        #expect(!coordinator.deliveryIsPaused)
        #expect(scheduler.scheduledReminders.count == 2)
        try library.add(text: "New body", tags: ["Body"])
        await coordinator.waitForLibraryRefresh()
        #expect(!coordinator.isPaused(morning))
        #expect(scheduler.scheduledReminders.count == 4)
        #expect(store.schedules.allSatisfy { $0.isEnabled })
    }

    @Test func browsingSelectionDoesNotChangeDelivery() async throws {
        let store = ScheduleStore(schedule: morning())
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(affirmationStore: AffirmationStore(affirmations: [body, confidence, food]),
                                                  scheduleStore: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        let previous = scheduler.scheduledReminders
        let replacements = scheduler.replaceCallCount
        try await coordinator.setSelection(.tag("Food"))
        #expect(coordinator.selectedAffirmations == [food])
        #expect(scheduler.scheduledReminders == previous)
        #expect(scheduler.replaceCallCount == replacements)
    }

    @Test func disablingAndDeletingKeepOtherSchedules() async throws {
        let morning = morning(), evening = evening()
        let store = ScheduleStore(schedule: morning)
        try store.replace(with: [morning, evening])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(affirmationStore: AffirmationStore(affirmations: [body, food]),
                                                  scheduleStore: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        let eveningReminders = scheduler.scheduledReminders.filter { $0.affirmationText == "Food" }
        try await coordinator.setEnabled(false, for: morning.id)
        #expect(scheduler.scheduledReminders == eveningReminders)
        try await coordinator.deleteSchedule(id: morning.id)
        #expect(store.schedules == [evening])
        #expect(scheduler.scheduledReminders == eveningReminders)
        try await coordinator.deleteSchedule(id: evening.id)
        #expect(store.schedules.isEmpty)
        #expect(scheduler.scheduledReminders.isEmpty)
    }

    @Test func combinedBudgetRejectsBeforeChangingDelivery() async throws {
        var morning = morning()
        morning.notificationsPerDay = 24
        let store = ScheduleStore(schedule: morning)
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(affirmationStore: AffirmationStore(affirmations: [body, food]),
                                                  scheduleStore: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        let previous = scheduler.scheduledReminders
        await #expect(throws: ScheduleValidationError.dailyLimit) { try await coordinator.saveSchedule(evening()) }
        #expect(store.schedules == [morning])
        #expect(scheduler.scheduledReminders == previous)
        var disabled = evening()
        disabled.isEnabled = false
        try await coordinator.saveSchedule(disabled)
        #expect(store.schedules.count == 2)
        #expect(scheduler.scheduledReminders == previous)
    }

    @Test("Failed replacement or save restores the entire previous plan", arguments: [false, true])
    func failedUpdateRestoresAllSchedules(failSave: Bool) async throws {
        let repository = CollectionScheduleRepository()
        let morning = morning(), evening = evening()
        repository.schedules = [morning, evening]
        let store = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(affirmationStore: AffirmationStore(affirmations: [body, confidence, food]),
                                                  scheduleStore: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        let previous = scheduler.scheduledReminders
        repository.failSave = failSave
        scheduler.failuresRemaining = failSave ? 0 : 1
        var updated = morning
        updated.selection = .tag("Food")
        await #expect(throws: NotificationSchedulerTestError.self) { try await coordinator.saveSchedule(updated) }
        #expect(store.schedules == [morning, evening])
        #expect(repository.schedules == [morning, evening])
        #expect(scheduler.scheduledReminders == previous)
    }

    @Test func migrationCapturesLegacySelectionOnceAndPreservesSettings() throws {
        let suite = "MultipleSchedules.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        let legacy = Data("""
        {"isEnabled":true,"startTime":{"hour":7,"minute":0},"endTime":{"hour":9,"minute":0},
        "notificationsPerDay":3,"sound":"none","rhythm":"moreEarly","emphasis":"gentle"}
        """.utf8)
        defaults.set(legacy, forKey: "gayffirmations.schedule")
        let selection = AffirmationSelection.sources(favourites: true, tags: ["Body", "Confidence"])
        try repository.saveAffirmationSelection(selection)
        let loaded = try #require(try repository.loadSchedules())
        #expect(loaded.count == 1)
        #expect(loaded[0].selection == selection)
        #expect(loaded[0].name == "Daily affirmations")
        #expect(loaded[0].isEnabled)
        #expect(loaded[0].startTime == TimeOfDay(hour: 7, minute: 0))
        #expect(loaded[0].endTime == TimeOfDay(hour: 9, minute: 0))
        #expect(loaded[0].notificationsPerDay == 3)
        #expect(loaded[0].rhythm == .moreEarly)
        #expect(loaded[0].emphasis == .gentle)
        #expect(loaded[0].sound == .none)
        try repository.saveAffirmationSelection(.all)
        #expect(try repository.loadSchedules() == loaded)
        #expect(defaults.object(forKey: "gayffirmations.schedule") == nil)
        try repository.saveSchedules(loaded + [evening()])
        let restarted = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        #expect(restarted.schedules.count == 2)
        try repository.saveSchedules([])
        #expect(try repository.loadSchedules() == [])
    }

    @Test func corruptLegacySelectionBlocksMigrationWithoutChangingData() throws {
        let suite = "MultipleSchedules.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = try JSONEncoder().encode(morning())
        defaults.set(legacy, forKey: "gayffirmations.schedule")
        defaults.set(Data("invalid".utf8), forKey: "gayffirmations.affirmationSelection")
        let store = ScheduleStore(repository: UserDefaultsRepository(userDefaults: defaults), defaultSchedule: AffirmationSchedule())
        #expect(store.persistenceErrorMessage != nil)
        #expect(defaults.data(forKey: "gayffirmations.schedule") == legacy)
        #expect(defaults.object(forKey: "gayffirmations.schedules") == nil)
    }

    @Test func resetAllPersistsOneDisabledDefaultSchedule() async throws {
        let suite = "MultipleSchedules.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsRepository(userDefaults: defaults)
        try repository.saveSchedules([morning(), evening()])
        let store = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let library = AffirmationStore(affirmations: [body, food])
        let scheduler = NotificationSchedulerSpy(authorizationStatus: .authorized)
        let coordinator = NotificationCoordinator(affirmationStore: library, scheduleStore: store, scheduler: scheduler)
        await coordinator.reconcileOnLaunch()
        let reset = AppDataResetCoordinator(affirmationStore: library, scheduleStore: store, themeStore: ThemeStore(),
                                            notificationCoordinator: coordinator, repository: repository)
        try reset.resetAll()
        #expect(store.schedules == [store.defaultSchedule])
        #expect(try repository.loadSchedules() == [store.defaultSchedule])
        #expect(!store.schedules[0].isEnabled)
        #expect(scheduler.scheduledReminders.isEmpty)
    }

    @Test func invalidCollectionIsPreservedAndCannotBeOverwritten() throws {
        let suite = "MultipleSchedules.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let schedule = morning()
        let invalid = try JSONEncoder().encode([schedule, schedule])
        defaults.set(invalid, forKey: "gayffirmations.schedules")
        let store = ScheduleStore(repository: UserDefaultsRepository(userDefaults: defaults), defaultSchedule: AffirmationSchedule())
        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) { try store.reset() }
        #expect(defaults.data(forKey: "gayffirmations.schedules") == invalid)
    }

    @Test func unusablePersonalizedContentUsesFallbackUntilReady() {
        let template = Affirmation(text: "Hello {name}", tags: ["Body"])
        let resolver = TodayAffirmationResolver()
        let fallback = resolver.context(at: date(hour: 12), schedules: [morning()], affirmations: [template, food],
                                        fallbackSelection: .tag("Food"), name: "", calendar: calendar)
        #expect(fallback.affirmation == food)
        #expect(fallback.nextChange == date(day: 2, hour: 0))
        let ready = resolver.context(at: date(hour: 12), schedules: [morning()], affirmations: [template, food],
                                     fallbackSelection: .tag("Food"), name: "Alex", calendar: calendar)
        #expect(ready.affirmation?.text == "Hello Alex")
    }
}

private final class CollectionScheduleRepository: ScheduleRepository {
    var schedules: [AffirmationSchedule]?
    var failSave = false
    func loadSchedules() throws -> [AffirmationSchedule]? { schedules }
    func saveSchedules(_ schedules: [AffirmationSchedule]) throws {
        if failSave { throw NotificationSchedulerTestError.failed }
        self.schedules = schedules
    }
}
