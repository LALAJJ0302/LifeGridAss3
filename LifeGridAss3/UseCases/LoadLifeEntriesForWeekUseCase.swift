import Foundation

/// Loads the private reflections saved for one LifeGrid week.
struct LoadLifeEntriesForWeekUseCase {
    private let repository: any LifeEntryRepository

    init(repository: any LifeEntryRepository) {
        self.repository = repository
    }

    func execute(lifeWeekNumber: Int) async -> [LifeEntry] {
        guard lifeWeekNumber >= 0 else { return [] }
        return (try? await repository.entries(forLifeWeek: lifeWeekNumber)) ?? []
    }
}
