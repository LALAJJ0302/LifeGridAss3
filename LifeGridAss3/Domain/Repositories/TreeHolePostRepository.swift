import Foundation

/// Storage operations for anonymously shared community reflections.
protocol TreeHolePostRepository: Sendable {
    func publish(_ post: TreeHolePost) async throws
    func post(id: TreeHolePost.ID) async throws -> TreeHolePost?

    /// Fetches recent posts, optionally matching the emotional state the user
    /// wants support with. The lower-bound date is inclusive.
    func recentPosts(
        matching emotionalState: EmotionalState?,
        since date: Date,
        limit: Int
    ) async throws -> [TreeHolePost]
}
