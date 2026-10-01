import Foundation
import Testing
@testable import LifeGridAss3

struct OfflineFirstUserProfileRepositoryTests {
    private let profile = UserProfile(
        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
        birthDate: Date(timeIntervalSince1970: 600_000_000),
        lifespanFrameYears: 80,
        createdAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    @Test("Cloud failure does not prevent a durable local save")
    func remoteFailureDoesNotBlockLocalSave() async throws {
        let local = MockUserProfileRepository()
        let remote = MockUserProfileRepository()
        await remote.forceSaveFailure()
        let repository = OfflineFirstUserProfileRepository(
            local: local,
            remote: remote
        )

        try await repository.save(profile)

        #expect(await local.currentProfile() == profile)
    }

    @Test("Synchronization restores a cloud profile to an empty device")
    func cloudProfileRestoresLocalProfile() async {
        let local = MockUserProfileRepository()
        let remote = MockUserProfileRepository(profile: profile)
        let repository = OfflineFirstUserProfileRepository(
            local: local,
            remote: remote
        )

        let synchronizedProfile = await repository.synchronize()

        #expect(synchronizedProfile == profile)
        #expect(await local.currentProfile() == profile)
    }

    @Test("Synchronization uploads the local source of truth")
    func localProfileIsUploaded() async {
        let local = MockUserProfileRepository(profile: profile)
        let remote = MockUserProfileRepository()
        let repository = OfflineFirstUserProfileRepository(
            local: local,
            remote: remote
        )

        let synchronizedProfile = await repository.synchronize()

        #expect(synchronizedProfile == profile)
        #expect(await remote.currentProfile() == profile)
    }

    @Test("The protected file repository round-trips a profile")
    func protectedFileRoundTrip() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent("profile.json")
        let repository = FileUserProfileRepository(fileURL: fileURL)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        try await repository.save(profile)
        let restoredProfile = try await repository.currentProfile()

        #expect(restoredProfile == profile)
    }
}
