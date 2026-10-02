import Foundation
import Testing
@testable import LifeGridAss3

struct ImportSharedReflectionDraftUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("A reviewed shared draft becomes a private reflection and leaves the inbox")
    func reviewedDraftIsImported() async throws {
        let draft = SharedReflectionDraft(
            suggestedText: "An idea shared from Notes",
            createdAt: now
        )
        let draftRepository = TestDraftRepository(drafts: [draft])
        let lifeEntryRepository = TestRepository()
        let useCase = makeUseCase(
            lifeEntryRepository: lifeEntryRepository,
            draftRepository: draftRepository
        )

        let entry = try await useCase.execute(
            draft: draft,
            reviewedMessage: "  My reviewed private thought  ",
            emotionalState: .hopeful,
            lifeWeekNumber: 1_303,
            now: now
        )

        #expect(entry.message == "My reviewed private thought")
        #expect(entry.lifeWeekNumber == 1_303)
        #expect(await lifeEntryRepository.savedEntries() == [entry])
        #expect(await draftRepository.drafts().isEmpty)
    }

    @Test("An empty shared draft cannot become a reflection")
    func emptyDraftIsRejected() async {
        let draft = SharedReflectionDraft(suggestedText: "Original")
        let draftRepository = TestDraftRepository(drafts: [draft])
        let lifeEntryRepository = TestRepository()
        let useCase = makeUseCase(
            lifeEntryRepository: lifeEntryRepository,
            draftRepository: draftRepository
        )

        await #expect(throws: ImportSharedReflectionDraftError.emptyDraft) {
            try await useCase.execute(
                draft: draft,
                reviewedMessage: "   ",
                emotionalState: nil,
                lifeWeekNumber: 1_303
            )
        }

        #expect(await lifeEntryRepository.savedEntries().isEmpty)
        #expect(await draftRepository.drafts() == [draft])
    }

    private func makeUseCase(
        lifeEntryRepository: TestRepository,
        draftRepository: TestDraftRepository
    ) -> ImportSharedReflectionDraftUseCase {
        ImportSharedReflectionDraftUseCase(
            recordLifeEntry: RecordLifeEntryUseCase(
                repository: lifeEntryRepository
            ),
            draftRepository: draftRepository
        )
    }
}
