import Foundation

/// Uses protected on-device storage for immediate access and treats private
/// CloudKit as the synchronization destination.
actor OfflineFirstUserProfileRepository: UserProfileSyncRepository {
    private let local: any UserProfileRepository
    private let makeRemote: @Sendable () -> any UserProfileRepository
    private var cachedRemote: (any UserProfileRepository)?

    init(
        local: any UserProfileRepository,
        remote: @autoclosure @escaping @Sendable () -> any UserProfileRepository
    ) {
        self.local = local
        makeRemote = remote
    }

    func save(_ profile: UserProfile) async throws {
        // The user-facing action succeeds as soon as the protected local copy
        // is durable. Cloud synchronization must never block onboarding.
        try await local.save(profile)

        let remote = remoteRepository()
        Task {
            try? await remote.save(profile)
        }
    }

    func currentProfile() async throws -> UserProfile? {
        try await local.currentProfile()
    }

    func synchronize() async -> UserProfile? {
        let remote = remoteRepository()

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

    private func remoteRepository() -> any UserProfileRepository {
        if let cachedRemote {
            return cachedRemote
        }

        let remote = makeRemote()
        cachedRemote = remote
        return remote
    }
}
