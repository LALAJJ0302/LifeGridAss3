import Combine
import Foundation

@MainActor
final class LifeEntryEditorViewModel: ObservableObject {
    @Published var message = ""
    @Published var emotionalState: EmotionalState?
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published private(set) var savedMessage: String?

    private let recordLifeEntry: RecordLifeEntryUseCase

    init(recordLifeEntry: RecordLifeEntryUseCase) {
        self.recordLifeEntry = recordLifeEntry
    }

    var remainingCharacters: Int {
        RecordLifeEntryUseCase.maximumMessageLength - message.count
    }

    var canSave: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && remainingCharacters >= 0
            && !isSaving
    }

    func save(lifeWeekNumber: Int) async -> LifeEntry? {
        guard canSave else { return nil }
        isSaving = true
        errorMessage = nil
        savedMessage = nil
        defer { isSaving = false }

        do {
            let entry = try await recordLifeEntry.execute(
                message: message,
                emotionalState: emotionalState,
                lifeWeekNumber: lifeWeekNumber
            )
            message = ""
            emotionalState = nil
            savedMessage = "Your reflection is saved privately."
            return entry
        } catch let error as LocalizedError {
            errorMessage = [error.errorDescription, error.recoverySuggestion]
                .compactMap { $0 }
                .joined(separator: " ")
        } catch {
            errorMessage = "Your reflection could not be saved. Please try again."
        }

        return nil
    }
}
