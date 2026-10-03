import Foundation

enum LoadSupportRepliesError: Error, Equatable, LocalizedError {
    case couldNotOpenReplies

    var errorDescription: String? {
        "Supportive replies could not be opened."
    }

    var recoverySuggestion: String? {
        "Try opening this Tree Hole post again."
    }
}

struct LoadSupportRepliesUseCase {
    private let repository: any SupportReplyRepository

    init(repository: any SupportReplyRepository) {
        self.repository = repository
    }

    func execute(for postID: TreeHolePost.ID) async throws -> [SupportReply] {
        do {
            return try await repository.replies(for: postID)
                .sorted { $0.createdAt < $1.createdAt }
        } catch {
            throw LoadSupportRepliesError.couldNotOpenReplies
        }
    }
}
