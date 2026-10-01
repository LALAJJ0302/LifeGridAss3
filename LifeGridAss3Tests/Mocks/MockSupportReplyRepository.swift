import Foundation
@testable import LifeGridAss3

actor MockSupportReplyRepository: SupportReplyRepository {
    private var storedReplies: [SupportReply]
    private let shouldFail: Bool

    init(replies: [SupportReply] = [], shouldFail: Bool = false) {
        storedReplies = replies
        self.shouldFail = shouldFail
    }

    func send(_ reply: SupportReply) throws {
        if shouldFail { throw MockSupportReplyRepositoryError.unavailable }
        storedReplies.append(reply)
    }

    func replies(for postID: TreeHolePost.ID) throws -> [SupportReply] {
        if shouldFail { throw MockSupportReplyRepositoryError.unavailable }
        return storedReplies.filter { $0.postID == postID }
    }

    func allReplies() -> [SupportReply] {
        storedReplies
    }
}

enum MockSupportReplyRepositoryError: Error {
    case unavailable
}
