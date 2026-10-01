import Foundation

enum CreateUserProfileError: Error, Equatable, LocalizedError {
    case futureBirthDate
    case invalidLifespanFrame
    case couldNotSave

    var errorDescription: String? {
        switch self {
        case .futureBirthDate:
            "Birth date cannot be in the future."
        case .invalidLifespanFrame:
            "Choose a lifespan frame between 1 and 120 years."
        case .couldNotSave:
            "LifeGrid could not save your profile."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .futureBirthDate:
            "Check the selected date and try again."
        case .invalidLifespanFrame:
            "Adjust the lifespan frame and try again."
        case .couldNotSave:
            "Check your iCloud connection and try again."
        }
    }
}
