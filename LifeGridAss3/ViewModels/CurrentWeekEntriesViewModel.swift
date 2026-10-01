import Combine
import Foundation

@MainActor
final class CurrentWeekEntriesViewModel: ObservableObject {
    @Published private(set) var entries: [LifeEntry] = []
    @Published private(set) var isLoading = false

    private let loadEntries: LoadLifeEntriesForWeekUseCase

    init(loadEntries: LoadLifeEntriesForWeekUseCase) {
        self.loadEntries = loadEntries
    }

    func load(lifeWeekNumber: Int) async {
        isLoading = true
        entries = await loadEntries.execute(lifeWeekNumber: lifeWeekNumber)
            .sorted { $0.occurredAt > $1.occurredAt }
        isLoading = false
    }

    func entrySaved(_ entry: LifeEntry) {
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
        entries.sort { $0.occurredAt > $1.occurredAt }
    }
}
