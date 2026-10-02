import Foundation
import Testing
@testable import LifeGridAss3

struct TreeHoleDraftViewModelTests {
    @Test("Editing the public copy never changes the private reflection")
    @MainActor
    func publicDraftIsIndependentFromPrivateEntry() async {
        let privateEntry = LifeEntry(
            message: "My private wording and identifying details",
            emotionalState: .hopeful,
            lifeWeekNumber: 1_250
        )
        let repository = TestRepository()
        let viewModel = TreeHoleDraftViewModel(
            sourceEntry: privateEntry,
            publishPost: PublishTreeHolePostUseCase(
                repository: repository,
                safetyChecker: RuleBasedContentSafetyChecker()
            )
        )

        viewModel.publicMessage = "A safer, anonymous public version"
        viewModel.hasConfirmedAnonymousSharing = true
        let didPublish = await viewModel.publish()

        #expect(didPublish)
        #expect(privateEntry.message == "My private wording and identifying details")
        #expect(
            await repository.publishedPosts().first?.message
                == "A safer, anonymous public version"
        )
    }
}
