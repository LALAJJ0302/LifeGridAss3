import Combine
import Foundation

@MainActor
final class SharedDraftInboxViewModel: ObservableObject {
    @Published private(set) var drafts: [SharedReflectionDraft] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let loadDrafts: LoadSharedReflectionDraftsUseCase

    init(loadDrafts: LoadSharedReflectionDraftsUseCase) {
        self.loadDrafts = loadDrafts
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            drafts = try await loadDrafts.execute()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Shared drafts could not be opened."
        }
    }

    func imported(_ draft: SharedReflectionDraft) {
        drafts.removeAll { $0.id == draft.id }
    }
}
