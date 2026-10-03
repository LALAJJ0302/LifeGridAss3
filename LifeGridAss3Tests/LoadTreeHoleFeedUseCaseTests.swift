import Foundation
import Testing
@testable import LifeGridAss3

struct LoadTreeHoleFeedUseCaseTests {
    @Test("The feed is newest first and can filter by emotion")
    func feedOrderingAndFiltering() async throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let olderCalm = TreeHolePost(
            message: "A calm older post",
            emotionalState: .calm,
            createdAt: now.addingTimeInterval(-200)
        )
        let newerHopeful = TreeHolePost(
            message: "A hopeful newer post",
            emotionalState: .hopeful,
            createdAt: now.addingTimeInterval(-100)
        )
        let repository = TestRepository(
            posts: [olderCalm, newerHopeful]
        )
        let useCase = LoadTreeHoleFeedUseCase(repository: repository)

        let allPosts = try await useCase.execute(matching: nil, now: now)
        let calmPosts = try await useCase.execute(matching: .calm, now: now)

        #expect(allPosts == [newerHopeful, olderCalm])
        #expect(calmPosts == [olderCalm])
    }

    @Test("A feed storage failure becomes a Tree Hole error")
    func storageFailureIsTranslated() async {
        let repository = TestRepository(shouldFail: true)
        let useCase = LoadTreeHoleFeedUseCase(repository: repository)

        await #expect(throws: LoadTreeHoleFeedError.couldNotOpenTreeHole) {
            try await useCase.execute(matching: nil)
        }
    }
}
