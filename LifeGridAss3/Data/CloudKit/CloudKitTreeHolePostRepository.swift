import CloudKit
import Foundation

/// Stores sanitised community posts in CloudKit's public database.
/// No private LifeEntry or UserProfile identifiers are written here.
actor CloudKitTreeHolePostRepository: TreeHolePostRepository {
    private enum Schema {
        static let recordType = "TreeHolePost"

        enum Field {
            static let message = "message"
            static let emotionalState = "emotionalState"
            static let createdAt = "createdAt"
        }
    }

    private let database: CKDatabase

    init(container: CKContainer = .default()) {
        database = container.publicCloudDatabase
    }

    init(database: CKDatabase) {
        self.database = database
    }

    func publish(_ post: TreeHolePost) async throws {
        let record = CKRecord(
            recordType: Schema.recordType,
            recordID: CKRecord.ID(recordName: post.id.uuidString)
        )
        record[Schema.Field.message] = post.message
        record[Schema.Field.emotionalState] = post.emotionalState.rawValue
        record[Schema.Field.createdAt] = post.createdAt
        _ = try await database.save(record)
    }

    func post(id: TreeHolePost.ID) async throws -> TreeHolePost? {
        do {
            let record = try await database.record(
                for: CKRecord.ID(recordName: id.uuidString)
            )
            return try makePost(from: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func recentPosts(
        matching emotionalState: EmotionalState?,
        since date: Date,
        limit: Int
    ) async throws -> [TreeHolePost] {
        var predicates = [
            NSPredicate(
                format: "%K >= %@",
                Schema.Field.createdAt,
                date as NSDate
            )
        ]

        if let emotionalState {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    Schema.Field.emotionalState,
                    emotionalState.rawValue
                )
            )
        }

        let query = CKQuery(
            recordType: Schema.recordType,
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        )
        query.sortDescriptors = [
            NSSortDescriptor(key: Schema.Field.createdAt, ascending: false)
        ]

        let page = try await database.records(
            matching: query,
            resultsLimit: max(1, limit)
        )

        return try page.matchResults.map { _, result in
            try makePost(from: result.get())
        }
    }

    private func makePost(from record: CKRecord) throws -> TreeHolePost {
        guard
            let id = UUID(uuidString: record.recordID.recordName),
            let message = record[Schema.Field.message] as? String,
            let emotionalStateValue = record[Schema.Field.emotionalState] as? String,
            let emotionalState = EmotionalState(rawValue: emotionalStateValue),
            let createdAt = record[Schema.Field.createdAt] as? Date
        else {
            throw CloudKitTreeHolePostRepositoryError.invalidRecord
        }

        return TreeHolePost(
            id: id,
            message: message,
            emotionalState: emotionalState,
            createdAt: createdAt
        )
    }
}

enum CloudKitTreeHolePostRepositoryError: Error, Equatable {
    case invalidRecord
}
