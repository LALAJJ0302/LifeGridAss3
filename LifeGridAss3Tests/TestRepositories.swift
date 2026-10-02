import Foundation
@testable import LifeGridAss3

/// One small in-memory repository used by the unit tests.
actor TestRepository:
    UserProfileRepository,
    LifeEntryRepository,
    TreeHolePostRepository,
    SupportReplyRepository {

    enum TestError: Error {
        case forcedFailure
    }

    private var profile: UserProfile?
    private var entries: [LifeEntry]
    private var posts: [TreeHolePost]
    private var replies: [SupportReply]
    private var shouldFail: Bool

    init(
        profile: UserProfile? = nil,
        entries: [LifeEntry] = [],
        posts: [TreeHolePost] = [],
        replies: [SupportReply] = [],
        shouldFail: Bool = false
    ) {
        self.profile = profile
        self.entries = entries
        self.posts = posts
        self.replies = replies
        self.shouldFail = shouldFail
    }

    func forceFailure() {
        shouldFail = true
    }

    func save(_ profile: UserProfile) throws {
        if shouldFail { throw TestError.forcedFailure }
        self.profile = profile
    }

    func currentProfile() -> UserProfile? {
        profile
    }

    func save(_ entry: LifeEntry) throws {
        if shouldFail { throw TestError.forcedFailure }
        entries.append(entry)
    }

    func update(_ entry: LifeEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            return
        }
        entries[index] = entry
    }

    func entry(id: LifeEntry.ID) -> LifeEntry? {
        entries.first { $0.id == id }
    }

    func entries(forLifeWeek week: Int) -> [LifeEntry] {
        entries.filter { $0.lifeWeekNumber == week }
    }

    func savedEntries() -> [LifeEntry] {
        entries
    }

    func publish(_ post: TreeHolePost) {
        posts.append(post)
    }

    func post(id: TreeHolePost.ID) -> TreeHolePost? {
        posts.first { $0.id == id }
    }

    func recentPosts(
        matching emotionalState: EmotionalState?,
        since date: Date,
        limit: Int
    ) -> [TreeHolePost] {
        posts
            .filter {
                $0.createdAt >= date
                    && (emotionalState == nil || $0.emotionalState == emotionalState)
            }
            .prefix(limit)
            .map { $0 }
    }

    func publishedPosts() -> [TreeHolePost] {
        posts
    }

    func send(_ reply: SupportReply) throws {
        if shouldFail { throw TestError.forcedFailure }
        replies.append(reply)
    }

    func replies(for postID: TreeHolePost.ID) throws -> [SupportReply] {
        if shouldFail { throw TestError.forcedFailure }
        return replies.filter { $0.postID == postID }
    }

    func allReplies() -> [SupportReply] {
        replies
    }
}

actor TestDraftRepository: SharedReflectionDraftRepository {
    private var storedDrafts: [SharedReflectionDraft]

    init(drafts: [SharedReflectionDraft] = []) {
        storedDrafts = drafts
    }

    func drafts() -> [SharedReflectionDraft] {
        storedDrafts
    }

    func remove(id: SharedReflectionDraft.ID) {
        storedDrafts.removeAll { $0.id == id }
    }
}
