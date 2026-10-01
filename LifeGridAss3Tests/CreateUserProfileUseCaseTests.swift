import Foundation
import Testing
@testable import LifeGridAss3

struct CreateUserProfileUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("A valid birth date creates and saves a profile")
    func validProfileIsSaved() async throws {
        let repository = MockUserProfileRepository()
        let calendar = Calendar(identifier: .gregorian)
        let useCase = CreateUserProfileUseCase(
            repository: repository,
            calendar: calendar
        )
        let birthDate = calendar.date(
            byAdding: .year,
            value: -24,
            to: now
        )!

        let profile = try await useCase.execute(
            birthDate: birthDate,
            lifespanFrameYears: 90,
            now: now
        )

        #expect(profile.lifespanFrameYears == 90)
        #expect(profile.birthDate == calendar.startOfDay(for: birthDate))
        #expect(await repository.currentProfile() == profile)
    }

    @Test("A future birth date is rejected before saving")
    func futureBirthDateIsRejected() async {
        let repository = MockUserProfileRepository()
        let useCase = CreateUserProfileUseCase(repository: repository)
        let tomorrow = now.addingTimeInterval(86_400)

        await #expect(throws: CreateUserProfileError.futureBirthDate) {
            try await useCase.execute(birthDate: tomorrow, now: now)
        }

        #expect(await repository.currentProfile() == nil)
    }

    @Test("An unrealistic lifespan frame is rejected")
    func invalidLifespanFrameIsRejected() async {
        let repository = MockUserProfileRepository()
        let useCase = CreateUserProfileUseCase(repository: repository)

        await #expect(throws: CreateUserProfileError.invalidLifespanFrame) {
            try await useCase.execute(
                birthDate: now,
                lifespanFrameYears: 121,
                now: now
            )
        }

        #expect(await repository.currentProfile() == nil)
    }

    @Test("A profile storage failure becomes a user-facing error")
    func storageFailureIsTranslated() async {
        let repository = MockUserProfileRepository()
        await repository.forceSaveFailure()
        let useCase = CreateUserProfileUseCase(repository: repository)

        await #expect(throws: CreateUserProfileError.couldNotSave) {
            try await useCase.execute(birthDate: now, now: now)
        }
    }
}
