import Foundation
import Testing
@testable import LifeGridAss3

struct LoadSupportRepliesUseCaseTests {
    @Test("Only replies for the selected post are returned oldest first")
    func filtersAndOrdersReplies() async throws {
        let selectedPostID = UUID()
        let otherPostID = UUID()
        let older = SupportReply(
            postID: selectedPostID,
            message: "Older",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newer = SupportReply(
            postID: selectedPostID,
            message: "Newer",
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let unrelated = SupportReply(
            postID: otherPostID,
            message: "Different post",
            createdAt: Date(timeIntervalSince1970: 50)
        )
        let repository = MockSupportReplyRepository(
            replies: [newer, unrelated, older]
        )

        let replies = try await LoadSupportRepliesUseCase(
            repository: repository
        ).execute(for: selectedPostID)

        #expect(replies == [older, newer])
    }
}
