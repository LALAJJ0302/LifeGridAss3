import Foundation

/// Storage operations for supportive responses to public Tree Hole posts.
protocol SupportReplyRepository: Sendable {
    func send(_ reply: SupportReply) async throws
    func replies(for postID: TreeHolePost.ID) async throws -> [SupportReply]
}
