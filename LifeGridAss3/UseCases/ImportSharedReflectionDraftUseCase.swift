import Foundation

enum ImportSharedReflectionDraftError: Error, Equatable, LocalizedError {
    case emptyDraft
    case couldNotSaveReflection
    case savedButCouldNotClearDraft

    var errorDescription: String? {
        switch self {
        case .emptyDraft:
            "Add some text before saving this shared draft."
        case .couldNotSaveReflection:
            "LifeGrid could not save this draft as a private reflection."
        case .savedButCouldNotClearDraft:
            "The reflection was saved, but its draft could not be removed."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyDraft:
            "Write a short private reflection and try again."
        case .couldNotSaveReflection:
            "Your draft is still here. Check storage access and try again."
        case .savedButCouldNotClearDraft:
            "Return to the inbox and remove the duplicate draft later."
        }
    }
}

struct ImportSharedReflectionDraftUseCase {
    private let recordLifeEntry: RecordLifeEntryUseCase
    private let draftRepository: any SharedReflectionDraftRepository

    init(
        recordLifeEntry: RecordLifeEntryUseCase,
        draftRepository: any SharedReflectionDraftRepository
    ) {
        self.recordLifeEntry = recordLifeEntry
        self.draftRepository = draftRepository
    }

    func execute(
        draft: SharedReflectionDraft,
        reviewedMessage: String,
        emotionalState: EmotionalState?,
        lifeWeekNumber: Int,
        now: Date = .now
    ) async throws -> LifeEntry {
        guard !reviewedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportSharedReflectionDraftError.emptyDraft
        }

        let entry: LifeEntry
        do {
            entry = try await recordLifeEntry.execute(
                message: reviewedMessage,
                emotionalState: emotionalState,
                occurredAt: now,
                lifeWeekNumber: lifeWeekNumber,
                now: now
            )
        } catch {
            throw ImportSharedReflectionDraftError.couldNotSaveReflection
        }

        do {
            try await draftRepository.remove(id: draft.id)
        } catch {
            throw ImportSharedReflectionDraftError.savedButCouldNotClearDraft
        }

        return entry
    }
}
