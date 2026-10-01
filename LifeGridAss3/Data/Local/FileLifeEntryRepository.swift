import Foundation

/// Stores private reflections in one protected JSON file inside the app
/// sandbox. The actor prevents concurrent writes from corrupting the file.
actor FileLifeEntryRepository: LifeEntryRepository {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(using: fileManager)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func save(_ entry: LifeEntry) throws {
        var entries = try loadEntries()
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
        try write(entries)
    }

    func update(_ entry: LifeEntry) throws {
        try save(entry)
    }

    func entry(id: LifeEntry.ID) throws -> LifeEntry? {
        try loadEntries().first { $0.id == id }
    }

    func entries(forLifeWeek week: Int) throws -> [LifeEntry] {
        try loadEntries()
            .filter { $0.lifeWeekNumber == week }
            .sorted { $0.occurredAt < $1.occurredAt }
    }

    private func loadEntries() throws -> [LifeEntry] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([LifeEntry].self, from: data)
    }

    private func write(_ entries: [LifeEntry]) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(entries)
        try data.write(
            to: fileURL,
            options: [.atomic, .completeFileProtection]
        )
    }

    private static func defaultFileURL(using fileManager: FileManager) -> URL {
        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        return applicationSupportURL
            .appendingPathComponent("LifeGrid", isDirectory: true)
            .appendingPathComponent("life-entries.json")
    }
}
