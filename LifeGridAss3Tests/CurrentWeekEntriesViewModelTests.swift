import Foundation
import Testing
@testable import LifeGridAss3

struct CurrentWeekEntriesViewModelTests {
    @Test("Only the requested life week is displayed, newest first")
    @MainActor
    func loadsCurrentWeekNewestFirst() async {
        let week = 1_250
        let older = makeEntry(
            message: "Morning reflection",
            time: 1_800_000_000,
            week: week
        )
        let newer = makeEntry(
            message: "Evening reflection",
            time: 1_800_000_100,
            week: week
        )
        let differentWeek = makeEntry(
            message: "Last week's reflection",
            time: 1_799_000_000,
            week: week - 1
        )
        let repository = TestRepository(
            entries: [older, differentWeek, newer]
        )
        let viewModel = CurrentWeekEntriesViewModel(
            loadEntries: LoadLifeEntriesForWeekUseCase(
                repository: repository
            )
        )

        await viewModel.load(lifeWeekNumber: week)

        #expect(viewModel.entries == [newer, older])
        #expect(viewModel.isLoading == false)
    }

    @Test("A newly saved reflection appears without reloading storage")
    @MainActor
    func insertsNewlySavedEntryImmediately() {
        let repository = TestRepository()
        let viewModel = CurrentWeekEntriesViewModel(
            loadEntries: LoadLifeEntriesForWeekUseCase(
                repository: repository
            )
        )
        let entry = makeEntry(
            message: "Visible as soon as save succeeds",
            time: 1_800_000_000,
            week: 1_250
        )

        viewModel.entrySaved(entry)

        #expect(viewModel.entries == [entry])
    }

    private func makeEntry(
        message: String,
        time: TimeInterval,
        week: Int
    ) -> LifeEntry {
        let date = Date(timeIntervalSince1970: time)
        return LifeEntry(
            message: message,
            occurredAt: date,
            createdAt: date,
            lifeWeekNumber: week
        )
    }
}
