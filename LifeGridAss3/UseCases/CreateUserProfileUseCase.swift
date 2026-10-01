import Foundation

/// Validates the information used to build a LifeGrid and saves the resulting
/// profile through an abstract repository.
struct CreateUserProfileUseCase {
    static let allowedLifespanFrames = 1...120

    private let repository: any UserProfileRepository
    private let calendar: Calendar

    init(
        repository: any UserProfileRepository,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    @discardableResult
    func execute(
        birthDate: Date,
        lifespanFrameYears: Int = 80,
        now: Date = .now
    ) async throws -> UserProfile {
        let birthDay = calendar.startOfDay(for: birthDate)
        let today = calendar.startOfDay(for: now)

        guard birthDay <= today else {
            throw CreateUserProfileError.futureBirthDate
        }

        guard Self.allowedLifespanFrames.contains(lifespanFrameYears) else {
            throw CreateUserProfileError.invalidLifespanFrame
        }

        let profile = UserProfile(
            birthDate: birthDay,
            lifespanFrameYears: lifespanFrameYears,
            createdAt: now
        )

        do {
            try await repository.save(profile)
            return profile
        } catch {
            throw CreateUserProfileError.couldNotSave
        }
    }
}
