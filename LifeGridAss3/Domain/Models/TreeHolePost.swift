import Foundation

/// A sanitised reflection that the user has explicitly chosen to publish to
/// the anonymous community.
struct TreeHolePost: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let message: String
    let emotionalState: EmotionalState
    let createdAt: Date

    init(
        id: UUID = UUID(),
        message: String,
        emotionalState: EmotionalState,
        createdAt: Date = .now
    ) {
        self.id = id
        self.message = message
        self.emotionalState = emotionalState
        self.createdAt = createdAt
    }
}
