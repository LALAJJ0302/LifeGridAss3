import Foundation

enum LoadSharedReflectionDraftsError: Error, Equatable, LocalizedError {
    case couldNotOpenInbox

    var errorDescription: String? {
        "LifeGrid could not open drafts received from other apps."
    }

    var recoverySuggestion: String? {
        "Check the App Group capability, then try again."
    }
}

struct LoadSharedReflectionDraftsUseCase {
    private let repository: any SharedReflectionDraftRepository

    init(repository: any SharedReflectionDraftRepository) {
        self.repository = repository
    }

    func execute() async throws -> [SharedReflectionDraft] {
        do {
            return try await repository.drafts()
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            throw LoadSharedReflectionDraftsError.couldNotOpenInbox
        }
    }
}
