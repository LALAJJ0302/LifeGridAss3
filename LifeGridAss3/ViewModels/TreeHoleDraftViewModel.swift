import Combine
import Foundation

@MainActor
final class TreeHoleDraftViewModel: ObservableObject {
    @Published var publicMessage: String
    @Published var emotionalState: EmotionalState?
    @Published var hasConfirmedAnonymousSharing = false
    @Published private(set) var isPublishing = false
    @Published var errorMessage: String?

    private let publishPost: PublishTreeHolePostUseCase

    init(
        sourceEntry: LifeEntry,
        publishPost: PublishTreeHolePostUseCase
    ) {
        publicMessage = sourceEntry.message
        emotionalState = sourceEntry.emotionalState
        self.publishPost = publishPost
    }

    var remainingCharacters: Int {
        PublishTreeHolePostUseCase.maximumMessageLength - publicMessage.count
    }

    var canPublish: Bool {
        !publicMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && remainingCharacters >= 0
            && emotionalState != nil
            && hasConfirmedAnonymousSharing
            && !isPublishing
    }

    func publish() async -> Bool {
        guard canPublish, let emotionalState else { return false }
        isPublishing = true
        errorMessage = nil
        defer { isPublishing = false }

        do {
            try await publishPost.execute(
                publicMessage: publicMessage,
                emotionalState: emotionalState,
                hasConfirmedAnonymousSharing: hasConfirmedAnonymousSharing
            )
            return true
        } catch let error as LocalizedError {
            errorMessage = [error.errorDescription, error.recoverySuggestion]
                .compactMap { $0 }
                .joined(separator: " ")
        } catch {
            errorMessage = "The Tree Hole post could not be published."
        }

        return false
    }
}
