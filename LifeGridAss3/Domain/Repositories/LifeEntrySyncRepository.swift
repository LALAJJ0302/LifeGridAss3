import Foundation

/// A life-entry repository that can reconcile protected local records with
/// their private CloudKit copies.
protocol LifeEntrySyncRepository: LifeEntryRepository {
    func synchronize(forLifeWeek week: Int) async -> [LifeEntry]
}
