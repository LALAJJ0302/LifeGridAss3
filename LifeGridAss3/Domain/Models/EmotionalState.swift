import Foundation

/// The emotional vocabulary LifeGrid uses for private reflection and
/// anonymous community posts.
///
/// A closed set prevents inconsistent values such as "sad", "Sad", and
/// "sadd" from being stored as different states.
enum EmotionalState: String, CaseIterable, Codable, Identifiable, Sendable {
    case calm
    case hopeful
    case grateful
    case sad
    case anxious
    case overwhelmed

    var id: String { rawValue }
}
