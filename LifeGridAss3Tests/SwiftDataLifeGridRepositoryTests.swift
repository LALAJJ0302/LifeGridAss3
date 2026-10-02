import Foundation
import Testing
@testable import LifeGridAss3

struct SwiftDataLifeGridRepositoryTests {
    @Test("SwiftData saves and loads a private reflection")
    func savesAndLoadsLifeEntry() async throws {
        let repository = try SwiftDataLifeGridRepository(inMemory: true)
        let entry = LifeEntry(
            message: "A private reflection",
            emotionalState: .hopeful,
            occurredAt: Date(timeIntervalSince1970: 1_800_000_000),
            lifeWeekNumber: 1_250
        )

        try await repository.save(entry)
        let entries = try await repository.entries(forLifeWeek: 1_250)

        #expect(entries == [entry])
    }

    @Test("SwiftData saves a Tree Hole post and its reply")
    func savesPostAndReply() async throws {
        let repository = try SwiftDataLifeGridRepository(inMemory: true)
        let post = TreeHolePost(
            message: "I would like some encouragement today.",
            emotionalState: .calm
        )
        let reply = SupportReply(
            postID: post.id,
            message: "You are not alone."
        )

        try await repository.publish(post)
        try await repository.send(reply)

        #expect(try await repository.post(id: post.id) == post)
        #expect(try await repository.replies(for: post.id) == [reply])
    }

    @Test("SwiftData keeps the current user profile")
    func savesCurrentProfile() async throws {
        let repository = try SwiftDataLifeGridRepository(inMemory: true)
        let profile = UserProfile(
            birthDate: Date(timeIntervalSince1970: 600_000_000),
            lifespanFrameYears: 80
        )

        try await repository.save(profile)

        #expect(try await repository.currentProfile() == profile)
    }
}
