import Testing
@testable import Gayffirmations

@MainActor
struct ScheduleStoreTests {
    @Test("Invalid reminder counts leave both saved and visible schedules unchanged", arguments: [-1, 0, 25, Int.max])
    func invalidCountPreservesSchedule(count: Int) {
        let repository = InMemoryScheduleRepository()
        let store = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        let original = store.schedule
        #expect(throws: ScheduleCalculatorError.invalidReminderCount) {
            try store.setNotificationsPerDay(count)
        }
        #expect(store.schedule == original)
        #expect(repository.schedule == original)
    }

    @Test("Valid reminder count boundaries and expanded counts survive restart", arguments: [1, 13, 24])
    func validCountsPersist(count: Int) throws {
        let repository = InMemoryScheduleRepository()
        let store = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())

        try store.setNotificationsPerDay(count)

        #expect(store.schedule.notificationsPerDay == count)
        #expect(repository.schedule?.notificationsPerDay == count)
        let restartedStore = ScheduleStore(repository: repository, defaultSchedule: AffirmationSchedule())
        #expect(restartedStore.schedule == store.schedule)
    }

    @Test("A saved schedule is loaded when a store is created")
    func loadsSavedSchedule() {
        let savedSchedule = AffirmationSchedule(
            isEnabled: true,
            startTime: TimeOfDay(hour: 7, minute: 30),
            endTime: TimeOfDay(hour: 20, minute: 0),
            notificationsPerDay: 6
        )
        let repository = InMemoryScheduleRepository(schedule: savedSchedule)

        let store = ScheduleStore(
            repository: repository,
            defaultSchedule: AffirmationSchedule()
        )

        #expect(store.schedule == savedSchedule)
    }

    @Test("The default schedule is saved on first launch")
    func savesDefaultSchedule() {
        let defaultSchedule = AffirmationSchedule()
        let repository = InMemoryScheduleRepository()

        let store = ScheduleStore(
            repository: repository,
            defaultSchedule: defaultSchedule
        )

        #expect(store.schedule == defaultSchedule)
        #expect(repository.schedule == defaultSchedule)
    }

    @Test("Schedule changes survive recreating the store")
    func changesSurviveRestart() throws {
        let repository = InMemoryScheduleRepository()
        let firstStore = ScheduleStore(
            repository: repository,
            defaultSchedule: AffirmationSchedule()
        )

        try firstStore.setEnabled(true)
        try firstStore.setStartTime(TimeOfDay(hour: 8, minute: 15))
        try firstStore.setEndTime(TimeOfDay(hour: 18, minute: 45))
        try firstStore.setNotificationsPerDay(7)

        let restartedStore = ScheduleStore(
            repository: repository,
            defaultSchedule: AffirmationSchedule()
        )

        #expect(restartedStore.schedule == firstStore.schedule)
    }

    @Test("Reset restores and saves the default schedule")
    func reset() throws {
        let defaultSchedule = AffirmationSchedule()
        let repository = InMemoryScheduleRepository()
        let store = ScheduleStore(
            repository: repository,
            defaultSchedule: defaultSchedule
        )

        try store.setEnabled(true)
        try store.setNotificationsPerDay(8)
        try store.reset()

        #expect(store.schedule == defaultSchedule)
        #expect(repository.schedule == defaultSchedule)
    }

    @Test("A load failure prevents the schedule from being overwritten")
    func loadFailurePreventsOverwrite() {
        let repository = FailingScheduleRepository()
        let store = ScheduleStore(
            repository: repository,
            defaultSchedule: AffirmationSchedule()
        )

        #expect(store.persistenceErrorMessage != nil)
        #expect(throws: PersistenceUnavailableError.self) {
            try store.setEnabled(true)
        }
        #expect(store.schedule.isEnabled == false)
        #expect(repository.saveCallCount == 0)
    }
}

private enum ScheduleRepositoryTestError: Error {
    case loadFailed
}

private final class FailingScheduleRepository: ScheduleRepository {
    private(set) var saveCallCount = 0

    func loadSchedule() throws -> AffirmationSchedule? {
        throw ScheduleRepositoryTestError.loadFailed
    }

    func saveSchedule(_ schedule: AffirmationSchedule) throws {
        saveCallCount += 1
    }
}

private final class InMemoryScheduleRepository: ScheduleRepository {
    var schedule: AffirmationSchedule?

    init(schedule: AffirmationSchedule? = nil) {
        self.schedule = schedule
    }

    func loadSchedule() throws -> AffirmationSchedule? {
        schedule
    }

    func saveSchedule(_ schedule: AffirmationSchedule) throws {
        self.schedule = schedule
    }
}
