import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: AppViewModel
    private let profileRepository: any UserProfileSyncRepository
    private let lifeEntryRepository: any LifeEntrySyncRepository

    init(
        profileRepository: any UserProfileSyncRepository,
        lifeEntryRepository: any LifeEntrySyncRepository
    ) {
        self.profileRepository = profileRepository
        self.lifeEntryRepository = lifeEntryRepository
        _viewModel = StateObject(
            wrappedValue: AppViewModel(profileRepository: profileRepository)
        )
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .loading:
                ProgressView("Opening your private LifeGrid…")

            case .profileSetup:
                ProfileSetupView(
                    createProfile: CreateUserProfileUseCase(
                        repository: profileRepository
                    ),
                    onProfileCreated: viewModel.profileCreated
                )

            case .ready(let profile):
                LifeGridHomeView(
                    profile: profile,
                    recordLifeEntry: RecordLifeEntryUseCase(
                        repository: lifeEntryRepository
                    ),
                    loadLifeEntries: LoadLifeEntriesForWeekUseCase(
                        repository: lifeEntryRepository
                    )
                )

            case .failed(let message):
                ContentUnavailableView {
                    Label("LifeGrid unavailable", systemImage: "icloud.slash")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again") {
                        Task { await viewModel.retryLoading() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task {
            await viewModel.loadProfileIfNeeded()
        }
    }
}
