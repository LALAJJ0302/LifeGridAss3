import Foundation
import Testing
@testable import LifeGridAss3

struct PublishTreeHolePostUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("A safe post is trimmed and published after explicit consent")
    func safePostIsPublished() async throws {
        let repository = TestRepository()
        let useCase = makeUseCase(repository: repository)

        let post = try await useCase.execute(
            publicMessage: "  I felt alone, but asking for help made today easier.  ",
            emotionalState: .hopeful,
            hasConfirmedAnonymousSharing: true,
            now: now
        )

        #expect(post.message == "I felt alone, but asking for help made today easier.")
        #expect(await repository.publishedPosts() == [post])
    }

    @Test("Publishing always requires explicit confirmation")
    func consentIsRequired() async {
        let repository = TestRepository()
        let useCase = makeUseCase(repository: repository)

        await #expect(throws: PublishTreeHolePostError.consentRequired) {
            try await useCase.execute(
                publicMessage: "A safe but unconfirmed post",
                emotionalState: .calm,
                hasConfirmedAnonymousSharing: false,
                now: now
            )
        }

        #expect(await repository.publishedPosts().isEmpty)
    }

    @Test("Violent content never reaches the public repository")
    func violentContentIsBlocked() async {
        let repository = TestRepository()
        let useCase = makeUseCase(repository: repository)

        await #expect(
            throws: PublishTreeHolePostError.unsafePublicContent([.violent])
        ) {
            try await useCase.execute(
                publicMessage: "I want to attack someone.",
                emotionalState: .overwhelmed,
                hasConfirmedAnonymousSharing: true,
                now: now
            )
        }

        #expect(await repository.publishedPosts().isEmpty)
    }

    @Test("Sexual content never reaches the public repository")
    func sexualContentIsBlocked() async {
        let repository = TestRepository()
        let useCase = makeUseCase(repository: repository)

        await #expect(
            throws: PublishTreeHolePostError.unsafePublicContent([.sexual])
        ) {
            try await useCase.execute(
                publicMessage: "This contains sexual material.",
                emotionalState: .anxious,
                hasConfirmedAnonymousSharing: true,
                now: now
            )
        }

        #expect(await repository.publishedPosts().isEmpty)
    }

    private func makeUseCase(
        repository: TestRepository
    ) -> PublishTreeHolePostUseCase {
        PublishTreeHolePostUseCase(
            repository: repository,
            safetyChecker: RuleBasedContentSafetyChecker()
        )
    }
}
