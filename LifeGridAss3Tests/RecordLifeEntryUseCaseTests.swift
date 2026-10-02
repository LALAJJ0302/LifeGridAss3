import Foundation
import Testing
@testable import LifeGridAss3

struct RecordLifeEntryUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("A meaningful private reflection is trimmed and saved")
    func meaningfulReflectionIsSaved() async throws {
        let repository = TestRepository()
        let useCase = RecordLifeEntryUseCase(repository: repository)

        let entry = try await useCase.execute(
            message: "  I asked for support today.  ",
            emotionalState: .hopeful,
            occurredAt: now,
            lifeWeekNumber: 1_250,
            now: now
        )

        let savedEntries = await repository.savedEntries()
        #expect(entry.message == "I asked for support today.")
        #expect(entry.emotionalState == .hopeful)
        #expect(savedEntries == [entry])
    }

    @Test("A private reflection does not require an emotional label")
    func unlabeledReflectionIsSaved() async throws {
        let repository = TestRepository()
        let useCase = RecordLifeEntryUseCase(repository: repository)

        let entry = try await useCase.execute(
            message: "I do not know how to name this feeling yet.",
            emotionalState: nil,
            occurredAt: now,
            lifeWeekNumber: 1_250,
            now: now
        )

        #expect(entry.emotionalState == nil)
        #expect(await repository.savedEntries() == [entry])
    }

    @Test("Whitespace cannot become an empty private reflection")
    func whitespaceOnlyReflectionIsRejected() async {
        let repository = TestRepository()
        let useCase = RecordLifeEntryUseCase(repository: repository)

        await #expect(throws: RecordLifeEntryError.emptyReflection) {
            try await useCase.execute(
                message: "  \n  ",
                emotionalState: .sad,
                occurredAt: now,
                lifeWeekNumber: 1_250,
                now: now
            )
        }

        #expect(await repository.savedEntries().isEmpty)
    }

    @Test("A reflection beyond the writing limit is rejected")
    func overlongReflectionIsRejected() async {
        let repository = TestRepository()
        let useCase = RecordLifeEntryUseCase(repository: repository)
        let message = String(
            repeating: "a",
            count: RecordLifeEntryUseCase.maximumMessageLength + 1
        )

        await #expect(
            throws: RecordLifeEntryError.reflectionTooLong(
                maximumCharacters: RecordLifeEntryUseCase.maximumMessageLength
            )
        ) {
            try await useCase.execute(
                message: message,
                emotionalState: .overwhelmed,
                occurredAt: now,
                lifeWeekNumber: 1_250,
                now: now
            )
        }

        #expect(await repository.savedEntries().isEmpty)
    }

    @Test("A future moment cannot be added to the LifeGrid")
    func futureMomentIsRejected() async {
        let repository = TestRepository()
        let useCase = RecordLifeEntryUseCase(repository: repository)
        let futureMoment = now.addingTimeInterval(60)

        await #expect(throws: RecordLifeEntryError.futureMomentNotAllowed) {
            try await useCase.execute(
                message: "This has not happened yet.",
                emotionalState: .anxious,
                occurredAt: futureMoment,
                lifeWeekNumber: 1_250,
                now: now
            )
        }

        #expect(await repository.savedEntries().isEmpty)
    }

    @Test("A life week cannot be negative")
    func negativeLifeWeekIsRejected() async {
        let repository = TestRepository()
        let useCase = RecordLifeEntryUseCase(repository: repository)

        await #expect(throws: RecordLifeEntryError.invalidLifeWeek) {
            try await useCase.execute(
                message: "A real memory still needs a valid week.",
                emotionalState: .grateful,
                occurredAt: now,
                lifeWeekNumber: -1,
                now: now
            )
        }

        #expect(await repository.savedEntries().isEmpty)
    }

    @Test("A storage failure becomes a human-centred save error")
    func storageFailureIsTranslatedForTheUser() async {
        let repository = TestRepository()
        await repository.forceFailure()
        let useCase = RecordLifeEntryUseCase(repository: repository)

        await #expect(throws: RecordLifeEntryError.couldNotSave) {
            try await useCase.execute(
                message: "I want to keep this reflection.",
                emotionalState: .calm,
                occurredAt: now,
                lifeWeekNumber: 1_250,
                now: now
            )
        }

        #expect(await repository.savedEntries().isEmpty)
    }
}
