import Foundation

/// A profile repository that can reconcile its local and remote copies.
protocol UserProfileSyncRepository: UserProfileRepository {
    /// Returns the newest available profile, or the local profile when the
    /// remote service is unavailable.
    func synchronize() async -> UserProfile?
}
