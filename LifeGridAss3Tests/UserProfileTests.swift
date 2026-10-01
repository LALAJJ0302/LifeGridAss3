import Foundation
import Testing
@testable import LifeGridAss3

struct UserProfileTests {
    @Test("A birth date in the future never creates negative lived weeks")
    func futureBirthDateProducesZeroLivedWeeks() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))
        )
        let futureBirthDate = try #require(
            calendar.date(from: DateComponents(year: 2027, month: 10, day: 1))
        )
        let profile = UserProfile(birthDate: futureBirthDate)

        #expect(profile.weeksLived(asOf: today, calendar: calendar) == 0)
    }

    @Test("Weeks lived never exceed the selected lifespan frame")
    func livedWeeksAreCappedAtTheFrame() throws {
        let calendar = Calendar(identifier: .gregorian)
        let birthDate = try #require(
            calendar.date(from: DateComponents(year: 1900, month: 1, day: 1))
        )
        let today = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))
        )
        let profile = UserProfile(
            birthDate: birthDate,
            lifespanFrameYears: 80
        )

        #expect(profile.weeksLived(asOf: today, calendar: calendar) == 4_160)
        #expect(profile.remainingWeeks(asOf: today, calendar: calendar) == 0)
    }
}
