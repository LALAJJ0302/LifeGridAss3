import Foundation

enum LoadLifeEntriesForWeekError: Error, Equatable, LocalizedError {
    case invalidLifeWeek
    case couldNotOpenWeek

    var errorDescription: String? {
        switch self {
        case .invalidLifeWeek:
            "LifeGrid could not recognise this life week."
        case .couldNotOpenWeek:
            "Your private reflections for this week could not be opened."
        }
    }

    var recoverySuggestion: String? {
        "Your reflections are still private. Try opening this week again."
    }
}

/// Loads the private reflections saved for one LifeGrid week.
struct LoadLifeEntriesForWeekUseCase {
    private let repository: any LifeEntryRepository

    init(repository: any LifeEntryRepository) {
        self.repository = repository
    }

    func execute(lifeWeekNumber: Int) async throws -> [LifeEntry] {
        guard lifeWeekNumber >= 0 else {
            throw LoadLifeEntriesForWeekError.invalidLifeWeek
        }

        do {
            return try await repository.entries(forLifeWeek: lifeWeekNumber)
        } catch {
            throw LoadLifeEntriesForWeekError.couldNotOpenWeek
        }
    }
}
