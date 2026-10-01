import Foundation

/// Storage operations required by LifeGrid's profile-related use cases.
protocol UserProfileRepository: Sendable {
    func save(_ profile: UserProfile) async throws
    func currentProfile() async throws -> UserProfile?
}
