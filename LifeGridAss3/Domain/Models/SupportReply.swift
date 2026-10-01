import Foundation

/// A short, supportive response attached to one public Tree Hole post.
struct SupportReply: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let postID: TreeHolePost.ID
    let message: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        postID: TreeHolePost.ID,
        message: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.postID = postID
        self.message = message
        self.createdAt = createdAt
    }
}
