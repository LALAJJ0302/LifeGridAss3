import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: AppViewModel
    private let profileRepository: any UserProfileRepository
    private let lifeEntryRepository: any LifeEntryRepository
    private let treeHolePostRepository: any TreeHolePostRepository
    private let supportReplyRepository: any SupportReplyRepository
    private let sharedDraftRepository: any SharedReflectionDraftRepository

    init(
        profileRepository: any UserProfileRepository,
        lifeEntryRepository: any LifeEntryRepository,
        treeHolePostRepository: any TreeHolePostRepository,
        supportReplyRepository: any SupportReplyRepository,
        sharedDraftRepository: any SharedReflectionDraftRepository
    ) {
        self.profileRepository = profileRepository
        self.lifeEntryRepository = lifeEntryRepository
        self.treeHolePostRepository = treeHolePostRepository
        self.supportReplyRepository = supportReplyRepository
        self.sharedDraftRepository = sharedDraftRepository
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
                TabView {
                    LifeGridHomeView(
                        profile: profile,
                        recordLifeEntry: RecordLifeEntryUseCase(
                            repository: lifeEntryRepository
                        ),
                        loadLifeEntries: LoadLifeEntriesForWeekUseCase(
                            repository: lifeEntryRepository
                        ),
                        publishTreeHolePost: PublishTreeHolePostUseCase(
                            repository: treeHolePostRepository,
                            safetyChecker: RuleBasedContentSafetyChecker()
                        )
                    )
                    .tabItem {
                        Label("LifeGrid", systemImage: "square.grid.3x3.fill")
                    }

                    TreeHoleFeedView(
                        loadPosts: LoadTreeHoleFeedUseCase(
                            repository: treeHolePostRepository
                        ),
                        supportReplyRepository: supportReplyRepository
                    )
                    .tabItem {
                        Label("Tree Hole", systemImage: "bubble.left.and.bubble.right.fill")
                    }

                    SharedDraftInboxView(
                        profile: profile,
                        recordLifeEntry: RecordLifeEntryUseCase(
                            repository: lifeEntryRepository
                        ),
                        draftRepository: sharedDraftRepository
                    )
                    .tabItem {
                        Label("Shared Drafts", systemImage: "square.and.arrow.down.fill")
                    }
                }

            case .failed(let message):
                ContentUnavailableView {
                    Label("LifeGrid unavailable", systemImage: "externaldrive.badge.exclamationmark")
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
