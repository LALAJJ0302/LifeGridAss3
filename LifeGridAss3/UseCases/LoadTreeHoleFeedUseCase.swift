import Foundation

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
        return try await repository.recentPosts(
            matching: emotionalState,
            since: thirtyDaysAgo,
            limit: 50
        )
        .sorted { $0.createdAt > $1.createdAt }
    }
}
