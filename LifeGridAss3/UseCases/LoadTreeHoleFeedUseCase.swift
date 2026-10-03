import Foundation

enum LoadTreeHoleFeedError: Error, Equatable, LocalizedError {
    case couldNotOpenTreeHole

    var errorDescription: String? {
        "The local Tree Hole could not be opened."
    }

    var recoverySuggestion: String? {
        "Your private reflections are not affected. Try opening the feed again."
    }
}

struct LoadTreeHoleFeedUseCase {
    private let repository: any TreeHolePostRepository

    init(repository: any TreeHolePostRepository) {
        self.repository = repository
    }

    func execute(
        matching emotionalState: EmotionalState?,
        now: Date = .now
    ) async throws -> [TreeHolePost] {
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
        do {
            return try await repository.recentPosts(
                matching: emotionalState,
                since: thirtyDaysAgo,
                limit: 50
            )
            .sorted { $0.createdAt > $1.createdAt }
        } catch {
            throw LoadTreeHoleFeedError.couldNotOpenTreeHole
        }
    }
}
