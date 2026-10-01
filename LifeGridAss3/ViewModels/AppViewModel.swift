import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    enum Phase {
        case loading
        case profileSetup
        case ready(UserProfile)
        case failed(String)
    }

    @Published private(set) var phase: Phase = .loading
    private let profileRepository: any UserProfileSyncRepository
    private var hasLoaded = false

    init(profileRepository: any UserProfileSyncRepository) {
        self.profileRepository = profileRepository
    }

    func loadProfileIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true

        do {
            if let profile = try await profileRepository.currentProfile() {
                phase = .ready(profile)
            } else {
                phase = .profileSetup
            }

            Task { [weak self] in
                await self?.synchronizeProfile()
            }
        } catch {
            phase = .failed(
                "We couldn't open the protected profile stored on this device."
            )
        }
    }

    func profileCreated(_ profile: UserProfile) {
        phase = .ready(profile)
    }

    func retryLoading() async {
        hasLoaded = false
        phase = .loading
        await loadProfileIfNeeded()
    }

    private func synchronizeProfile() async {
        if let synchronizedProfile = await profileRepository.synchronize() {
            phase = .ready(synchronizedProfile)
        }
    }
}
