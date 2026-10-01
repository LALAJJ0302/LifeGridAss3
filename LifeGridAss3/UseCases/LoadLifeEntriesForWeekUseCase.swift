import Foundation

/// Loads one LifeGrid week and reconciles its protected local reflections
/// with the user's private CloudKit database when the network is available.
struct LoadLifeEntriesForWeekUseCase {
    private let repository: any LifeEntrySyncRepository

    init(repository: any LifeEntrySyncRepository) {
        self.repository = repository
    }

    func execute(lifeWeekNumber: Int) async -> [LifeEntry] {
        guard lifeWeekNumber >= 0 else { return [] }
        return await repository.synchronize(forLifeWeek: lifeWeekNumber)
    }
}
