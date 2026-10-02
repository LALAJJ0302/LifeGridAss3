import Foundation

/// Failures a person can understand and recover from while recording a
/// private LifeGrid reflection.
enum RecordLifeEntryError: Error, Equatable, LocalizedError {
    case emptyReflection
    case reflectionTooLong(maximumCharacters: Int)
    case futureMomentNotAllowed
    case invalidLifeWeek
    case couldNotSave

    var errorDescription: String? {
        switch self {
        case .emptyReflection:
            "Write something about this moment before saving it."
        case let .reflectionTooLong(maximumCharacters):
            "This reflection is longer than the \(maximumCharacters)-character limit."
        case .futureMomentNotAllowed:
            "A reflection cannot be recorded for a moment that has not happened yet."
        case .invalidLifeWeek:
            "LifeGrid could not place this reflection in your timeline."
        case .couldNotSave:
            "LifeGrid could not save this reflection on this device."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyReflection:
            "Add a short private reflection and try again."
        case .reflectionTooLong:
            "Shorten the reflection and try again."
        case .futureMomentNotAllowed:
            "Choose the current time or an earlier moment."
        case .invalidLifeWeek:
            "Check your birth date in your LifeGrid profile and try again."
        case .couldNotSave:
            "Your writing is still on this screen. Try saving it again."
        }
    }
}
