import Foundation

/// Validates and records one sensitive reflection in the user's private
/// LifeGrid space.
struct RecordLifeEntryUseCase {
    static let maximumMessageLength = 2_000

    private let repository: any LifeEntryRepository

    init(repository: any LifeEntryRepository) {
        self.repository = repository
    }

    @discardableResult
    func execute(
        message: String,
        emotionalState: EmotionalState,
        occurredAt: Date = .now,
        lifeWeekNumber: Int,
        now: Date = .now
    ) async throws -> LifeEntry {
        let trimmedMessage = message.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedMessage.isEmpty else {
            throw RecordLifeEntryError.emptyReflection
        }

        guard trimmedMessage.count <= Self.maximumMessageLength else {
            throw RecordLifeEntryError.reflectionTooLong(
                maximumCharacters: Self.maximumMessageLength
            )
        }

        guard occurredAt <= now else {
            throw RecordLifeEntryError.futureMomentNotAllowed
        }

        guard lifeWeekNumber >= 0 else {
            throw RecordLifeEntryError.invalidLifeWeek
        }

        let entry = LifeEntry(
            message: trimmedMessage,
            emotionalState: emotionalState,
            occurredAt: occurredAt,
            createdAt: now,
            updatedAt: now,
            lifeWeekNumber: lifeWeekNumber
        )

        do {
            try await repository.save(entry)
            return entry
        } catch {
            throw RecordLifeEntryError.couldNotSave
        }
    }
}
