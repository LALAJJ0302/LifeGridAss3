import Foundation
@testable import LifeGridAss3

actor MockLifeEntryRepository: LifeEntrySyncRepository {
    enum MockFailure: Error {
        case forcedSaveFailure
    }

    private var storedEntries: [LifeEntry]
    private var shouldFailWhenSaving = false

    init(storedEntries: [LifeEntry] = []) {
        self.storedEntries = storedEntries
    }

    func save(_ entry: LifeEntry) throws {
        guard !shouldFailWhenSaving else {
            throw MockFailure.forcedSaveFailure
        }

        storedEntries.append(entry)
    }

    func update(_ entry: LifeEntry) {
        guard let index = storedEntries.firstIndex(where: { $0.id == entry.id }) else {
            return
        }

        storedEntries[index] = entry
    }

    func entry(id: LifeEntry.ID) -> LifeEntry? {
        storedEntries.first { $0.id == id }
    }

    func entries(forLifeWeek week: Int) -> [LifeEntry] {
        storedEntries.filter { $0.lifeWeekNumber == week }
    }

    func synchronize(forLifeWeek week: Int) -> [LifeEntry] {
        entries(forLifeWeek: week)
    }

    func forceSaveFailure() {
        shouldFailWhenSaving = true
    }

    func allowSaving() {
        shouldFailWhenSaving = false
    }

    func savedEntries() -> [LifeEntry] {
        storedEntries
    }
}
