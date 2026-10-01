import SwiftUI

struct SharedDraftInboxView: View {
    @Environment(\.scenePhase) private var scenePhase

    let profile: UserProfile
    let recordLifeEntry: RecordLifeEntryUseCase
    let draftRepository: any SharedReflectionDraftRepository
    @StateObject private var viewModel: SharedDraftInboxViewModel

    init(
        profile: UserProfile,
        recordLifeEntry: RecordLifeEntryUseCase,
        draftRepository: any SharedReflectionDraftRepository
    ) {
        self.profile = profile
        self.recordLifeEntry = recordLifeEntry
        self.draftRepository = draftRepository
        _viewModel = StateObject(
            wrappedValue: SharedDraftInboxViewModel(
                loadDrafts: LoadSharedReflectionDraftsUseCase(
                    repository: draftRepository
                )
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.drafts.isEmpty {
                    ProgressView("Opening shared drafts…")
                } else if viewModel.drafts.isEmpty {
                    ContentUnavailableView {
                        Label("No shared drafts", systemImage: "square.and.arrow.down")
                    } description: {
                        Text("Share meaningful text or a link from another app to review it privately in LifeGrid.")
                    }
                } else {
                    List(viewModel.drafts) { draft in
                        NavigationLink {
                            SharedDraftReviewView(
                                profile: profile,
                                draft: draft,
                                importDraft: ImportSharedReflectionDraftUseCase(
                                    recordLifeEntry: recordLifeEntry,
                                    draftRepository: draftRepository
                                ),
                                onImported: viewModel.imported
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(draft.suggestedText)
                                    .lineLimit(3)
                                Text(draft.createdAt.formatted(.relative(presentation: .named)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Shared Drafts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Label("Refresh drafts", systemImage: "arrow.clockwise")
                    }
                }
            }
            .refreshable { await viewModel.load() }
        }
        .task { await viewModel.load() }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            Task {
                await viewModel.load()
            }
        }
        .alert(
            "Drafts unavailable",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
