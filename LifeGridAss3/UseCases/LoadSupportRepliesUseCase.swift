import Foundation

struct LoadSupportRepliesUseCase {
    private let repository: any SupportReplyRepository

    init(repository: any SupportReplyRepository) {
        self.repository = repository
    }

    func execute(for postID: TreeHolePost.ID) async throws -> [SupportReply] {
        try await repository.replies(for: postID)
            .sorted { $0.createdAt < $1.createdAt }
    }
}
