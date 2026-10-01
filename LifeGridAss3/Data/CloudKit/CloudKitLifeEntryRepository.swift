import CloudKit
import Foundation

/// Stores sensitive LifeGrid reflections in the signed-in user's private
/// CloudKit database. Nothing in this repository writes to a public database.
actor CloudKitLifeEntryRepository: LifeEntryRepository {
    private enum Schema {
        static let recordType = "LifeEntry"

        enum Field {
            static let message = "message"
            static let emotionalState = "emotionalState"
            static let occurredAt = "occurredAt"
            static let createdAt = "createdAt"
            static let updatedAt = "updatedAt"
            static let lifeWeekNumber = "lifeWeekNumber"
            static let sharedAt = "sharedAt"
        }
    }

    private let database: CKDatabase

    init(container: CKContainer = .default()) {
        database = container.privateCloudDatabase
    }

    /// This initializer keeps the repository testable without changing the
    /// production database selection.
    init(database: CKDatabase) {
        self.database = database
    }

    func save(_ entry: LifeEntry) async throws {
        let record = CKRecord(
            recordType: Schema.recordType,
            recordID: recordID(for: entry.id)
        )
        apply(entry, to: record)
        _ = try await database.save(record)
    }

    func update(_ entry: LifeEntry) async throws {
        let record = try await database.record(for: recordID(for: entry.id))
        apply(entry, to: record)
        _ = try await database.save(record)
    }

    func entry(id: LifeEntry.ID) async throws -> LifeEntry? {
        do {
            let record = try await database.record(for: recordID(for: id))
            return try makeLifeEntry(from: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func entries(forLifeWeek week: Int) async throws -> [LifeEntry] {
        let predicate = NSPredicate(
            format: "%K == %@",
            Schema.Field.lifeWeekNumber,
            NSNumber(value: week)
        )
        let query = CKQuery(recordType: Schema.recordType, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: Schema.Field.occurredAt, ascending: true)
        ]

        return try await records(matching: query)
            .map(makeLifeEntry(from:))
    }

    private func recordID(for id: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    private func apply(_ entry: LifeEntry, to record: CKRecord) {
        record[Schema.Field.message] = entry.message
        record[Schema.Field.emotionalState] = entry.emotionalState.rawValue
        record[Schema.Field.occurredAt] = entry.occurredAt
        record[Schema.Field.createdAt] = entry.createdAt
        record[Schema.Field.updatedAt] = entry.updatedAt
        record[Schema.Field.lifeWeekNumber] = entry.lifeWeekNumber
        record[Schema.Field.sharedAt] = entry.sharedAt
    }

    private func makeLifeEntry(from record: CKRecord) throws -> LifeEntry {
        guard
            let id = UUID(uuidString: record.recordID.recordName),
            let message = record[Schema.Field.message] as? String,
            let emotionalStateValue = record[Schema.Field.emotionalState] as? String,
            let emotionalState = EmotionalState(rawValue: emotionalStateValue),
            let occurredAt = record[Schema.Field.occurredAt] as? Date,
            let createdAt = record[Schema.Field.createdAt] as? Date,
            let updatedAt = record[Schema.Field.updatedAt] as? Date,
            let lifeWeekNumber = record[Schema.Field.lifeWeekNumber] as? Int
        else {
            throw CloudKitLifeEntryRepositoryError.invalidRecord
        }

        return LifeEntry(
            id: id,
            message: message,
            emotionalState: emotionalState,
            occurredAt: occurredAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lifeWeekNumber: lifeWeekNumber,
            sharedAt: record[Schema.Field.sharedAt] as? Date
        )
    }

    private func records(matching query: CKQuery) async throws -> [CKRecord] {
        var collectedRecords: [CKRecord] = []
        var page = try await database.records(matching: query)

        try appendSuccessfulRecords(page.matchResults, to: &collectedRecords)

        while let cursor = page.queryCursor {
            page = try await database.records(continuingMatchFrom: cursor)
            try appendSuccessfulRecords(page.matchResults, to: &collectedRecords)
        }

        return collectedRecords
    }

    private func appendSuccessfulRecords(
        _ results: [(CKRecord.ID, Result<CKRecord, any Error>)],
        to records: inout [CKRecord]
    ) throws {
        for (_, result) in results {
            records.append(try result.get())
        }
    }
}

enum CloudKitLifeEntryRepositoryError: Error, Equatable {
    case invalidRecord
}
