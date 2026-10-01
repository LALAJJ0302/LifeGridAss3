import CloudKit
import Foundation

/// Stores the single current profile in the user's private CloudKit database.
actor CloudKitUserProfileRepository: UserProfileRepository {
    private enum Schema {
        static let recordType = "UserProfile"
        static let currentProfileRecordName = "current-user-profile"

        enum Field {
            static let profileID = "profileID"
            static let birthDate = "birthDate"
            static let lifespanFrameYears = "lifespanFrameYears"
            static let createdAt = "createdAt"
        }
    }

    private let database: CKDatabase

    init(container: CKContainer = .default()) {
        database = container.privateCloudDatabase
    }

    init(database: CKDatabase) {
        self.database = database
    }

    func save(_ profile: UserProfile) async throws {
        let recordID = currentProfileRecordID
        let record: CKRecord

        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(
                recordType: Schema.recordType,
                recordID: recordID
            )
        }

        record[Schema.Field.profileID] = profile.id.uuidString
        record[Schema.Field.birthDate] = profile.birthDate
        record[Schema.Field.lifespanFrameYears] = profile.lifespanFrameYears
        record[Schema.Field.createdAt] = profile.createdAt

        _ = try await database.save(record)
    }

    func currentProfile() async throws -> UserProfile? {
        do {
            let record = try await database.record(for: currentProfileRecordID)
            return try makeUserProfile(from: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private var currentProfileRecordID: CKRecord.ID {
        CKRecord.ID(recordName: Schema.currentProfileRecordName)
    }

    private func makeUserProfile(from record: CKRecord) throws -> UserProfile {
        guard
            let profileIDValue = record[Schema.Field.profileID] as? String,
            let profileID = UUID(uuidString: profileIDValue),
            let birthDate = record[Schema.Field.birthDate] as? Date,
            let lifespanFrameYears = record[Schema.Field.lifespanFrameYears] as? Int,
            let createdAt = record[Schema.Field.createdAt] as? Date
        else {
            throw CloudKitUserProfileRepositoryError.invalidRecord
        }

        return UserProfile(
            id: profileID,
            birthDate: birthDate,
            lifespanFrameYears: lifespanFrameYears,
            createdAt: createdAt
        )
    }
}

enum CloudKitUserProfileRepositoryError: Error, Equatable {
    case invalidRecord
}
