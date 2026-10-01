import Foundation
@testable import LifeGridAss3

actor MockSharedReflectionDraftRepository: SharedReflectionDraftRepository {
    private var storedDrafts: [SharedReflectionDraft]
    private let shouldFailRemoval: Bool

    init(
        drafts: [SharedReflectionDraft] = [],
        shouldFailRemoval: Bool = false
    ) {
        storedDrafts = drafts
        self.shouldFailRemoval = shouldFailRemoval
    }

    func drafts() -> [SharedReflectionDraft] {
        storedDrafts
    }

    func remove(id: SharedReflectionDraft.ID) throws {
        if shouldFailRemoval {
            throw MockSharedReflectionDraftRepositoryError.couldNotRemove
        }
        storedDrafts.removeAll { $0.id == id }
    }
}

enum MockSharedReflectionDraftRepositoryError: Error {
    case couldNotRemove
}
