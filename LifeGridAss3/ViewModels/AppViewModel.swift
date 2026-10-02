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
    private let profileRepository: any UserProfileRepository
    private var hasLoaded = false

    init(profileRepository: any UserProfileRepository) {
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
}
