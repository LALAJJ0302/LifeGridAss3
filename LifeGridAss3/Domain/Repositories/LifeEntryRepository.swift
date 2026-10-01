import Foundation

/// Storage operations required for the user's private reflections.
protocol LifeEntryRepository: Sendable {
    func save(_ entry: LifeEntry) async throws
    func update(_ entry: LifeEntry) async throws
    func entry(id: LifeEntry.ID) async throws -> LifeEntry?

    /// A domain-meaningful query used to populate one week in the LifeGrid.
    func entries(forLifeWeek week: Int) async throws -> [LifeEntry]
}
