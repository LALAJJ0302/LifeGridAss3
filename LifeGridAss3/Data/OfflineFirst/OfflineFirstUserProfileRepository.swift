import Foundation

/// Uses protected on-device storage for immediate access and treats private
/// CloudKit as the synchronization destination.
actor OfflineFirstUserProfileRepository: UserProfileSyncRepository {
    private let local: any UserProfileRepository
    private let remote: any UserProfileRepository

    init(
        local: any UserProfileRepository,
        remote: any UserProfileRepository
    ) {
        self.local = local
        self.remote = remote
    }

    func save(_ profile: UserProfile) async throws {
        // The user-facing action succeeds as soon as the protected local copy
        // is durable. Cloud synchronization must never block onboarding.
        try await local.save(profile)

        let remote = remote
        Task {
            try? await remote.save(profile)
        }
    }

    func currentProfile() async throws -> UserProfile? {
        try await local.currentProfile()
    }

    func synchronize() async -> UserProfile? {
        do {
            if let localProfile = try await local.currentProfile() {
                try await remote.save(localProfile)
                return localProfile
            }

            guard let remoteProfile = try await remote.currentProfile() else {
                return nil
            }

            try await local.save(remoteProfile)
            return remoteProfile
        } catch {
            return try? await local.currentProfile()
        }
    }
}
