import Foundation
import Testing
@testable import LifeGridAss3

struct OfflineFirstLifeEntryRepositoryTests {
    private let entryID = UUID(
        uuidString: "11111111-2222-3333-4444-555555555555"
    )!
    private let week = 1_250

    @Test("Cloud failure does not prevent a private local save")
    func cloudFailureDoesNotBlockSave() async throws {
        let local = MockLifeEntryRepository()
        let remote = MockLifeEntryRepository()
        await remote.forceSaveFailure()
        let repository = OfflineFirstLifeEntryRepository(
            local: local,
            remote: remote
        )
        let entry = makeEntry(message: "Saved safely on this device.")

        try await repository.save(entry)

        #expect(await local.entry(id: entry.id) == entry)
    }

    @Test("A locally saved reflection uploads when CloudKit becomes available")
    func localReflectionUploadsAfterCloudRecovery() async throws {
        let local = MockLifeEntryRepository()
        let remote = MockLifeEntryRepository()
        await remote.forceSaveFailure()
        let repository = OfflineFirstLifeEntryRepository(
            local: local,
            remote: remote
        )
        let entry = makeEntry(message: "Saved offline, then synchronized.")

        try await repository.save(entry)
        #expect(await local.entry(id: entry.id) == entry)
        #expect(await remote.entry(id: entry.id) == nil)

        await remote.allowSaving()
        let synchronized = await repository.synchronize(forLifeWeek: week)

        #expect(synchronized == [entry])
        #expect(await remote.entry(id: entry.id) == entry)
    }

    @Test("A newer cloud edit replaces an older local edit")
    func newerCloudEditWins() async {
        let localEntry = makeEntry(
            message: "Older local wording",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let cloudEntry = makeEntry(
            message: "Newer cloud wording",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
        )
        let local = MockLifeEntryRepository(storedEntries: [localEntry])
        let remote = MockLifeEntryRepository(storedEntries: [cloudEntry])
        let repository = OfflineFirstLifeEntryRepository(
            local: local,
            remote: remote
        )

        let synchronized = await repository.synchronize(forLifeWeek: week)

        #expect(synchronized == [cloudEntry])
        #expect(await local.entry(id: entryID) == cloudEntry)
    }

    @Test("A newer local edit replaces an older cloud edit")
    func newerLocalEditWins() async {
        let localEntry = makeEntry(
            message: "Newer local wording",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
        )
        let cloudEntry = makeEntry(
            message: "Older cloud wording",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let local = MockLifeEntryRepository(storedEntries: [localEntry])
        let remote = MockLifeEntryRepository(storedEntries: [cloudEntry])
        let repository = OfflineFirstLifeEntryRepository(
            local: local,
            remote: remote
        )

        let synchronized = await repository.synchronize(forLifeWeek: week)

        #expect(synchronized == [localEntry])
        #expect(await remote.entry(id: entryID) == localEntry)
    }

    @Test("The protected file repository round-trips private entries")
    func protectedFileRoundTrip() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent("entries.json")
        let repository = FileLifeEntryRepository(fileURL: fileURL)
        let entry = makeEntry(message: "A private reflection")
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        try await repository.save(entry)
        let restoredEntries = try await repository.entries(forLifeWeek: week)

        #expect(restoredEntries == [entry])
    }

    private func makeEntry(
        message: String,
        updatedAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> LifeEntry {
        LifeEntry(
            id: entryID,
            message: message,
            emotionalState: .hopeful,
            occurredAt: Date(timeIntervalSince1970: 1_799_000_000),
            createdAt: Date(timeIntervalSince1970: 1_799_000_000),
            updatedAt: updatedAt,
            lifeWeekNumber: week
        )
    }
}
