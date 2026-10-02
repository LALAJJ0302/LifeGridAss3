import Foundation
import SwiftData

actor SwiftDataLifeGridRepository:
    UserProfileRepository,
    LifeEntryRepository,
    TreeHolePostRepository,
    SupportReplyRepository {

    enum StorageError: Error {
        case postNotFound
    }

    private let container: ModelContainer

    init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(
            for: UserProfileRecord.self,
            LifeEntryRecord.self,
            TreeHolePostRecord.self,
            SupportReplyRecord.self,
            configurations: configuration
        )
    }

    func save(_ profile: UserProfile) throws {
        let context = ModelContext(container)
        let profileID = profile.id
        let descriptor = FetchDescriptor<UserProfileRecord>(
            predicate: #Predicate { $0.id == profileID }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.birthDate = profile.birthDate
            existing.lifespanFrameYears = profile.lifespanFrameYears
        } else {
            context.insert(UserProfileRecord(profile: profile))
        }

        try context.save()
    }

    func currentProfile() throws -> UserProfile? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<UserProfileRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.domainModel
    }

    func save(_ entry: LifeEntry) throws {
        try upsert(entry)
    }

    func update(_ entry: LifeEntry) throws {
        try upsert(entry)
    }

    func entry(id: LifeEntry.ID) throws -> LifeEntry? {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<LifeEntryRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.domainModel
    }

    func entries(forLifeWeek week: Int) throws -> [LifeEntry] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<LifeEntryRecord>(
            predicate: #Predicate { $0.lifeWeekNumber == week },
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.domainModel)
    }

    func publish(_ post: TreeHolePost) throws {
        let context = ModelContext(container)
        let postID = post.id
        let descriptor = FetchDescriptor<TreeHolePostRecord>(
            predicate: #Predicate { $0.id == postID }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.message = post.message
            existing.emotionalStateRawValue = post.emotionalState.rawValue
            existing.createdAt = post.createdAt
        } else {
            context.insert(TreeHolePostRecord(post: post))
        }

        try context.save()
    }

    func post(id: TreeHolePost.ID) throws -> TreeHolePost? {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TreeHolePostRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.domainModel
    }

    func recentPosts(
        matching emotionalState: EmotionalState?,
        since date: Date,
        limit: Int
    ) throws -> [TreeHolePost] {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<TreeHolePostRecord>(
            predicate: #Predicate { $0.createdAt >= date },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try context.fetch(descriptor)
            .compactMap(\.domainModel)
            .filter { emotionalState == nil || $0.emotionalState == emotionalState }
    }

    func send(_ reply: SupportReply) throws {
        let context = ModelContext(container)
        let postID = reply.postID
        let descriptor = FetchDescriptor<TreeHolePostRecord>(
            predicate: #Predicate { $0.id == postID }
        )

        guard let post = try context.fetch(descriptor).first else {
            throw StorageError.postNotFound
        }

        context.insert(SupportReplyRecord(reply: reply, post: post))
        try context.save()
    }

    func replies(for postID: TreeHolePost.ID) throws -> [SupportReply] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<SupportReplyRecord>(
            predicate: #Predicate { $0.postID == postID },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor).map(\.domainModel)
    }

    private func upsert(_ entry: LifeEntry) throws {
        let context = ModelContext(container)
        let entryID = entry.id
        let descriptor = FetchDescriptor<LifeEntryRecord>(
            predicate: #Predicate { $0.id == entryID }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.update(from: entry)
        } else {
            context.insert(LifeEntryRecord(entry: entry))
        }

        try context.save()
    }
}
