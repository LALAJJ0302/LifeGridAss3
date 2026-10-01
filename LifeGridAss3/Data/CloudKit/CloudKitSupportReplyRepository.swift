import CloudKit
import Foundation

/// Stores anonymous supportive replies in CloudKit's public database.
/// Replies reference only a public TreeHolePost ID, never a private LifeEntry.
actor CloudKitSupportReplyRepository: SupportReplyRepository {
    private enum Schema {
        static let recordType = "SupportReply"

        enum Field {
            static let postReference = "postReference"
            static let message = "message"
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

    func send(_ reply: SupportReply) async throws {
        let record = CKRecord(
            recordType: Schema.recordType,
            recordID: CKRecord.ID(recordName: reply.id.uuidString)
        )
        record[Schema.Field.postReference] = CKRecord.Reference(
            recordID: treeHolePostRecordID(for: reply.postID),
            action: .none
        )
        record[Schema.Field.message] = reply.message
        record[Schema.Field.createdAt] = reply.createdAt
        _ = try await database.save(record)
    }

    func replies(for postID: TreeHolePost.ID) async throws -> [SupportReply] {
        let query = CKQuery(
            recordType: Schema.recordType,
            predicate: NSPredicate(
                format: "%K == %@",
                Schema.Field.postReference,
                CKRecord.Reference(
                    recordID: treeHolePostRecordID(for: postID),
                    action: .none
                )
            )
        )
        query.sortDescriptors = [
            NSSortDescriptor(key: Schema.Field.createdAt, ascending: true)
        ]

        let page = try await database.records(
            matching: query,
            resultsLimit: 100
        )

        return try page.matchResults.map { _, result in
            try makeReply(from: result.get())
        }
    }

    private func makeReply(from record: CKRecord) throws -> SupportReply {
        guard
            let id = UUID(uuidString: record.recordID.recordName),
            let postReference = record[Schema.Field.postReference] as? CKRecord.Reference,
            let postID = UUID(uuidString: postReference.recordID.recordName),
            let message = record[Schema.Field.message] as? String,
            let createdAt = record[Schema.Field.createdAt] as? Date
        else {
            throw CloudKitSupportReplyRepositoryError.invalidRecord
        }

        return SupportReply(
            id: id,
            postID: postID,
            message: message,
            createdAt: createdAt
        )
    }

    private func treeHolePostRecordID(
        for postID: TreeHolePost.ID
    ) -> CKRecord.ID {
        CKRecord.ID(recordName: postID.uuidString)
    }
}

enum CloudKitSupportReplyRepositoryError: Error, Equatable {
    case invalidRecord
}
