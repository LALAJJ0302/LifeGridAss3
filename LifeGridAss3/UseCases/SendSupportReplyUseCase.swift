import Foundation

enum SendSupportReplyError: Error, Equatable, LocalizedError {
    case emptyReply
    case replyTooLong(maximumCharacters: Int)
    case unsafePublicContent(Set<UnsafeContentCategory>)
    case couldNotSend

    var errorDescription: String? {
        switch self {
        case .emptyReply:
            "Write a supportive reply before sending."
        case .replyTooLong(let maximumCharacters):
            "Replies must be \(maximumCharacters) characters or fewer."
        case .unsafePublicContent:
            "This reply cannot be shared because it may contain sexual or violent content."
        case .couldNotSend:
            "Your reply could not be saved on this device. Try again."
        }
    }
}

struct SendSupportReplyUseCase {
    static let maximumMessageLength = 240

    private let repository: any SupportReplyRepository
    private let safetyChecker: any ContentSafetyChecking

    init(
        repository: any SupportReplyRepository,
        safetyChecker: any ContentSafetyChecking
    ) {
        self.repository = repository
        self.safetyChecker = safetyChecker
    }

    @discardableResult
    func execute(
        postID: TreeHolePost.ID,
        message: String,
        now: Date = .now
    ) async throws -> SupportReply {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedMessage.isEmpty else {
            throw SendSupportReplyError.emptyReply
        }

        guard trimmedMessage.count <= Self.maximumMessageLength else {
            throw SendSupportReplyError.replyTooLong(
                maximumCharacters: Self.maximumMessageLength
            )
        }

        switch safetyChecker.evaluateForPublicSharing(trimmedMessage) {
        case .allowed:
            break
        case .blocked(let categories):
            throw SendSupportReplyError.unsafePublicContent(categories)
        }

        let reply = SupportReply(
            postID: postID,
            message: trimmedMessage,
            createdAt: now
        )

        do {
            try await repository.send(reply)
            return reply
        } catch {
            throw SendSupportReplyError.couldNotSend
        }
    }
}
