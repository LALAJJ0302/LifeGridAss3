import Foundation

enum PublishTreeHolePostError: Error, Equatable {
    case consentRequired
    case emptyPost
    case postTooLong(maximumCharacters: Int)
    case unsafePublicContent(Set<UnsafeContentCategory>)
    case couldNotPublish
}

extension PublishTreeHolePostError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .consentRequired:
            "Confirm anonymous public sharing before publishing."
        case .emptyPost:
            "Write something before publishing."
        case .postTooLong(let maximumCharacters):
            "Public posts must be \(maximumCharacters) characters or fewer."
        case .unsafePublicContent:
            "This reflection cannot be shared publicly because it may contain sexual or violent content."
        case .couldNotPublish:
            "The Tree Hole post could not be published."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unsafePublicContent:
            "It is still saved privately. Edit the public copy or keep it only in your LifeGrid."
        case .couldNotPublish:
            "LifeGrid could not save the post on this device. Try again."
        default:
            nil
        }
    }
}

/// Creates a new anonymous public record without moving, exposing, or
/// deleting the original private LifeEntry.
struct PublishTreeHolePostUseCase {
    static let maximumMessageLength = 500

    private let repository: any TreeHolePostRepository
    private let safetyChecker: any ContentSafetyChecking

    init(
        repository: any TreeHolePostRepository,
        safetyChecker: any ContentSafetyChecking
    ) {
        self.repository = repository
        self.safetyChecker = safetyChecker
    }

    @discardableResult
    func execute(
        publicMessage: String,
        emotionalState: EmotionalState,
        hasConfirmedAnonymousSharing: Bool,
        now: Date = .now
    ) async throws -> TreeHolePost {
        guard hasConfirmedAnonymousSharing else {
            throw PublishTreeHolePostError.consentRequired
        }

        let trimmedMessage = publicMessage.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedMessage.isEmpty else {
            throw PublishTreeHolePostError.emptyPost
        }

        guard trimmedMessage.count <= Self.maximumMessageLength else {
            throw PublishTreeHolePostError.postTooLong(
                maximumCharacters: Self.maximumMessageLength
            )
        }

        switch safetyChecker.evaluateForPublicSharing(trimmedMessage) {
        case .allowed:
            break
        case .blocked(let categories):
            throw PublishTreeHolePostError.unsafePublicContent(categories)
        }

        let post = TreeHolePost(
            message: trimmedMessage,
            emotionalState: emotionalState,
            createdAt: now
        )

        do {
            try await repository.publish(post)
            return post
        } catch {
            throw PublishTreeHolePostError.couldNotPublish
        }
    }
}
