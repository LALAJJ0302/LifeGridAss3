import Foundation
import SwiftData

@Model
final class UserProfileRecord {
    @Attribute(.unique) var id: UUID
    var birthDate: Date
    var lifespanFrameYears: Int
    var createdAt: Date

    init(profile: UserProfile) {
        id = profile.id
        birthDate = profile.birthDate
        lifespanFrameYears = profile.lifespanFrameYears
        createdAt = profile.createdAt
    }

    var domainModel: UserProfile {
        UserProfile(
            id: id,
            birthDate: birthDate,
            lifespanFrameYears: lifespanFrameYears,
            createdAt: createdAt
        )
    }
}

@Model
final class LifeEntryRecord {
    @Attribute(.unique) var id: UUID
    var message: String
    var emotionalStateRawValue: String?
    var occurredAt: Date
    var createdAt: Date
    var updatedAt: Date
    var lifeWeekNumber: Int
    var sharedAt: Date?

    init(entry: LifeEntry) {
        id = entry.id
        message = entry.message
        emotionalStateRawValue = entry.emotionalState?.rawValue
        occurredAt = entry.occurredAt
        createdAt = entry.createdAt
        updatedAt = entry.updatedAt
        lifeWeekNumber = entry.lifeWeekNumber
        sharedAt = entry.sharedAt
    }

    func update(from entry: LifeEntry) {
        message = entry.message
        emotionalStateRawValue = entry.emotionalState?.rawValue
        occurredAt = entry.occurredAt
        updatedAt = entry.updatedAt
        lifeWeekNumber = entry.lifeWeekNumber
        sharedAt = entry.sharedAt
    }

    var domainModel: LifeEntry {
        LifeEntry(
            id: id,
            message: message,
            emotionalState: emotionalStateRawValue.flatMap(EmotionalState.init(rawValue:)),
            occurredAt: occurredAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lifeWeekNumber: lifeWeekNumber,
            sharedAt: sharedAt
        )
    }
}

@Model
final class TreeHolePostRecord {
    @Attribute(.unique) var id: UUID
    var message: String
    var emotionalStateRawValue: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SupportReplyRecord.post)
    var replies: [SupportReplyRecord] = []

    init(post: TreeHolePost) {
        id = post.id
        message = post.message
        emotionalStateRawValue = post.emotionalState.rawValue
        createdAt = post.createdAt
    }

    var domainModel: TreeHolePost? {
        guard let emotionalState = EmotionalState(rawValue: emotionalStateRawValue) else {
            return nil
        }

        return TreeHolePost(
            id: id,
            message: message,
            emotionalState: emotionalState,
            createdAt: createdAt
        )
    }
}

@Model
final class SupportReplyRecord {
    @Attribute(.unique) var id: UUID
    var postID: UUID
    var message: String
    var createdAt: Date
    var post: TreeHolePostRecord?

    init(reply: SupportReply, post: TreeHolePostRecord) {
        id = reply.id
        postID = reply.postID
        message = reply.message
        createdAt = reply.createdAt
        self.post = post
    }

    var domainModel: SupportReply {
        SupportReply(
            id: id,
            postID: postID,
            message: message,
            createdAt: createdAt
        )
    }
}
