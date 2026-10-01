import Foundation

/// A sensitive reflection that always belongs to the user's private space.
///
/// Publishing never moves or deletes this record. A separate, sanitised
/// `TreeHolePost` is created only after explicit consent.
struct LifeEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let message: String
    let emotionalState: EmotionalState
    let occurredAt: Date
    let createdAt: Date
    let lifeWeekNumber: Int
    let sharedAt: Date?

    init(
        id: UUID = UUID(),
        message: String,
        emotionalState: EmotionalState,
        occurredAt: Date = .now,
        createdAt: Date = .now,
        lifeWeekNumber: Int,
        sharedAt: Date? = nil
    ) {
        self.id = id
        self.message = message
        self.emotionalState = emotionalState
        self.occurredAt = occurredAt
        self.createdAt = createdAt
        self.lifeWeekNumber = lifeWeekNumber
        self.sharedAt = sharedAt
    }

    var isSharedAnonymously: Bool {
        sharedAt != nil
    }
}
