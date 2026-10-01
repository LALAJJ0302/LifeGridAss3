import Foundation
import Testing
@testable import LifeGridAss3

struct SendSupportReplyUseCaseTests {
    private let postID = UUID()
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("A safe supportive reply is trimmed and stored")
    func safeReplyIsStored() async throws {
        let repository = MockSupportReplyRepository()
        let useCase = makeUseCase(repository: repository)

        let reply = try await useCase.execute(
            postID: postID,
            message: "  You are not alone. Thank you for sharing.  ",
            now: now
        )

        #expect(reply.message == "You are not alone. Thank you for sharing.")
        #expect(reply.postID == postID)
        #expect(await repository.allReplies() == [reply])
    }

    @Test("Empty replies are rejected")
    func emptyReplyIsRejected() async {
        let repository = MockSupportReplyRepository()
        let useCase = makeUseCase(repository: repository)

        await #expect(throws: SendSupportReplyError.emptyReply) {
            try await useCase.execute(postID: postID, message: "   ")
        }
        #expect(await repository.allReplies().isEmpty)
    }

    @Test("Violent replies never reach public storage")
    func violentReplyIsRejected() async {
        let repository = MockSupportReplyRepository()
        let useCase = makeUseCase(repository: repository)

        await #expect(
            throws: SendSupportReplyError.unsafePublicContent([.violent])
        ) {
            try await useCase.execute(
                postID: postID,
                message: "You should attack them."
            )
        }
        #expect(await repository.allReplies().isEmpty)
    }

    @Test("Repository failures become a user-facing send error")
    func storageFailureIsMapped() async {
        let repository = MockSupportReplyRepository(shouldFail: true)
        let useCase = makeUseCase(repository: repository)

        await #expect(throws: SendSupportReplyError.couldNotSend) {
            try await useCase.execute(
                postID: postID,
                message: "Thinking of you today."
            )
        }
    }

    private func makeUseCase(
        repository: MockSupportReplyRepository
    ) -> SendSupportReplyUseCase {
        SendSupportReplyUseCase(
            repository: repository,
            safetyChecker: RuleBasedContentSafetyChecker()
        )
    }
}
