import Foundation
@testable import LifeGridAss3

actor MockUserProfileRepository: UserProfileRepository {
    enum MockFailure: Error {
        case forcedSaveFailure
    }

    private var profile: UserProfile?
    private var shouldFailWhenSaving = false

    func save(_ profile: UserProfile) throws {
        guard !shouldFailWhenSaving else {
            throw MockFailure.forcedSaveFailure
        }

        self.profile = profile
    }

    func currentProfile() -> UserProfile? {
        profile
    }

    func forceSaveFailure() {
        shouldFailWhenSaving = true
    }
}
