import Foundation

enum UnsafeContentCategory: String, CaseIterable, Sendable {
    case sexual
    case violent
}

enum ContentSafetyResult: Equatable, Sendable {
    case allowed
    case blocked(Set<UnsafeContentCategory>)
}

/// A replaceable policy boundary for content that may enter the public
/// community. Private LifeEntry text is never evaluated by this interface.
protocol ContentSafetyChecking: Sendable {
    func evaluateForPublicSharing(_ text: String) -> ContentSafetyResult
}
