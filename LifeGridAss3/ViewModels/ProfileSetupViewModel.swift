import Combine
import Foundation

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    @Published var birthDate: Date
    @Published var lifespanFrameYears = 80
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let createProfile: CreateUserProfileUseCase
    private let existingProfile: UserProfile?

    var isEditing: Bool {
        existingProfile != nil
    }

    init(
        createProfile: CreateUserProfileUseCase,
        existingProfile: UserProfile? = nil,
        calendar: Calendar = .current
    ) {
        self.createProfile = createProfile
        self.existingProfile = existingProfile
        birthDate = existingProfile?.birthDate
            ?? calendar.date(byAdding: .year, value: -25, to: .now)
            ?? .now
        lifespanFrameYears = existingProfile?.lifespanFrameYears ?? 80
    }

    func submit() async -> UserProfile? {
        guard !isSaving else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            return try await createProfile.execute(
                birthDate: birthDate,
                lifespanFrameYears: lifespanFrameYears,
                existingProfile: existingProfile
            )
        } catch let error as LocalizedError {
            errorMessage = [error.errorDescription, error.recoverySuggestion]
                .compactMap { $0 }
                .joined(separator: " ")
            return nil
        } catch {
            errorMessage = "Something went wrong. Please try again."
            return nil
        }
    }
}
