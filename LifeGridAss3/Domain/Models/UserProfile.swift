import Foundation

/// The personal information required to calculate a LifeGrid.
///
/// The lifespan frame is a reflective visual boundary, not a prediction of
/// how long someone will live.
struct UserProfile: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let birthDate: Date
    let lifespanFrameYears: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        birthDate: Date,
        lifespanFrameYears: Int = 80,
        createdAt: Date = .now
    ) {
        self.id = id
        self.birthDate = birthDate
        self.lifespanFrameYears = lifespanFrameYears
        self.createdAt = createdAt
    }

    var totalWeeksInFrame: Int {
        lifespanFrameYears * 52
    }

    func weeksLived(
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let birthDay = calendar.startOfDay(for: birthDate)
        let referenceDay = calendar.startOfDay(for: date)
        let elapsedDays = calendar.dateComponents(
            [.day],
            from: birthDay,
            to: referenceDay
        ).day ?? 0

        return min(max(elapsedDays / 7, 0), totalWeeksInFrame)
    }

    func remainingWeeks(
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        max(totalWeeksInFrame - weeksLived(asOf: date, calendar: calendar), 0)
    }
}
