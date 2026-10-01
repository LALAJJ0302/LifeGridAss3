import Combine
import Foundation

@MainActor
final class SharedDraftReviewViewModel: ObservableObject {
    @Published var reviewedMessage: String
    @Published var emotionalState: EmotionalState?
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    let draft: SharedReflectionDraft
    private let importDraft: ImportSharedReflectionDraftUseCase

    init(
        draft: SharedReflectionDraft,
        importDraft: ImportSharedReflectionDraftUseCase
    ) {
        self.draft = draft
        self.importDraft = importDraft
        reviewedMessage = draft.suggestedText
    }

    var canSave: Bool {
        !reviewedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && reviewedMessage.count <= RecordLifeEntryUseCase.maximumMessageLength
            && !isSaving
    }

    var remainingCharacters: Int {
        RecordLifeEntryUseCase.maximumMessageLength - reviewedMessage.count
    }

    func save(lifeWeekNumber: Int) async -> LifeEntry? {
        guard canSave else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            return try await importDraft.execute(
                draft: draft,
                reviewedMessage: reviewedMessage,
                emotionalState: emotionalState,
                lifeWeekNumber: lifeWeekNumber
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "This draft could not be saved."
            return nil
        }
    }
}
