import Combine
import Foundation

@MainActor
final class CurrentWeekEntriesViewModel: ObservableObject {
    @Published private(set) var entries: [LifeEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let loadEntries: LoadLifeEntriesForWeekUseCase

    init(loadEntries: LoadLifeEntriesForWeekUseCase) {
        self.loadEntries = loadEntries
    }

    func load(lifeWeekNumber: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            entries = try await loadEntries.execute(
                lifeWeekNumber: lifeWeekNumber
            )
            .sorted { $0.occurredAt > $1.occurredAt }
        } catch {
            entries = []
            errorMessage = [
                (error as? LocalizedError)?.errorDescription,
                (error as? LocalizedError)?.recoverySuggestion
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        }
    }

    func entrySaved(_ entry: LifeEntry) {
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
        entries.sort { $0.occurredAt > $1.occurredAt }
    }
}
