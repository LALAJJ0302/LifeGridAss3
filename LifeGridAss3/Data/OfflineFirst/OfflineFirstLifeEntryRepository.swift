import Foundation

/// Reads and writes private reflections locally, then reconciles them with
/// private CloudKit records using a last-write-wins merge.
actor OfflineFirstLifeEntryRepository: LifeEntrySyncRepository {
    private let local: any LifeEntryRepository
    private let makeRemote: @Sendable () -> any LifeEntryRepository
    private var cachedRemote: (any LifeEntryRepository)?

    init(
        local: any LifeEntryRepository,
        remote: @autoclosure @escaping @Sendable () -> any LifeEntryRepository
    ) {
        self.local = local
        makeRemote = remote
    }

    func save(_ entry: LifeEntry) async throws {
        try await local.save(entry)

        let remote = remoteRepository()
        Task {
            try? await remote.save(entry)
        }
    }

    func update(_ entry: LifeEntry) async throws {
        try await local.update(entry)

        let remote = remoteRepository()
        Task {
            try? await remote.update(entry)
        }
    }

    func entry(id: LifeEntry.ID) async throws -> LifeEntry? {
        try await local.entry(id: id)
    }

    func entries(forLifeWeek week: Int) async throws -> [LifeEntry] {
        try await local.entries(forLifeWeek: week)
    }

    func synchronize(forLifeWeek week: Int) async -> [LifeEntry] {
        let localEntries = (try? await local.entries(forLifeWeek: week)) ?? []
        let remote = remoteRepository()

        do {
            let remoteEntries = try await remote.entries(forLifeWeek: week)
            let mergedEntries = merge(localEntries, remoteEntries)
            let localByID = Dictionary(uniqueKeysWithValues: localEntries.map { ($0.id, $0) })
            let remoteByID = Dictionary(uniqueKeysWithValues: remoteEntries.map { ($0.id, $0) })

            for entry in mergedEntries {
                if let localEntry = localByID[entry.id] {
                    if localEntry != entry {
                        try await local.update(entry)
                    }
                } else {
                    try await local.save(entry)
                }

                if let remoteEntry = remoteByID[entry.id] {
                    if remoteEntry != entry {
                        try await remote.update(entry)
                    }
                } else {
                    try await remote.save(entry)
                }
            }

            return mergedEntries.sorted { $0.occurredAt < $1.occurredAt }
        } catch {
            return localEntries
        }
    }

    private func merge(
        _ localEntries: [LifeEntry],
        _ remoteEntries: [LifeEntry]
    ) -> [LifeEntry] {
        var entriesByID = Dictionary(
            uniqueKeysWithValues: localEntries.map { ($0.id, $0) }
        )

        for remoteEntry in remoteEntries {
            guard let localEntry = entriesByID[remoteEntry.id] else {
                entriesByID[remoteEntry.id] = remoteEntry
                continue
            }

            if remoteEntry.updatedAt > localEntry.updatedAt {
                entriesByID[remoteEntry.id] = remoteEntry
            }
        }

        return Array(entriesByID.values)
    }

    private func remoteRepository() -> any LifeEntryRepository {
        if let cachedRemote {
            return cachedRemote
        }

        let remote = makeRemote()
        cachedRemote = remote
        return remote
    }
}
