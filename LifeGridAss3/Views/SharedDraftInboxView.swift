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
            ZStack {
                LinearGradient(
                    colors: [
                        Color.indigo.opacity(0.11),
                        Color.teal.opacity(0.07),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        LifeGridPageHeader(
                            context: "Private inbox",
                            title: "Shared Drafts",
                            subtitle: "Review first. You decide what becomes yours.",
                            symbol: "square.and.arrow.down.fill",
                            accent: .indigo,
                            actionSymbol: "arrow.clockwise",
                            action: {
                                Task { await viewModel.load() }
                            }
                        )

                        inboxContent
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }
                .refreshable { await viewModel.load() }
            }
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

    @ViewBuilder
    private var inboxContent: some View {
        if viewModel.isLoading && viewModel.drafts.isEmpty {
            VStack(spacing: 16) {
                DraftInboxAnimation()
                    .frame(width: 120, height: 120)
                    .accessibilityHidden(true)
                ProgressView("Opening shared drafts…")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        } else if viewModel.drafts.isEmpty {
            emptyInbox
        } else {
            draftList
        }
    }

    private var emptyInbox: some View {
        VStack(spacing: 24) {
            DraftInboxAnimation()
                .frame(width: 170, height: 170)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Bring meaningful moments into LifeGrid")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("Share text or a link from another app. You will always review it before it becomes a private reflection.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(alignment: .top, spacing: 8) {
                instructionStep(
                    number: "1",
                    icon: "square.and.arrow.up",
                    title: "Share"
                )
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .padding(.top, 22)
                instructionStep(
                    number: "2",
                    icon: "pencil.and.list.clipboard",
                    title: "Review"
                )
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .padding(.top, 22)
                instructionStep(
                    number: "3",
                    icon: "lock.fill",
                    title: "Save"
                )
            }
            .padding(18)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))

            Label(
                "Nothing is imported automatically",
                systemImage: "checkmark.shield.fill"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.teal)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.teal.opacity(0.10), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func instructionStep(
        number: String,
        icon: String,
        title: String
    ) -> some View {
        VStack(spacing: 7) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.indigo.gradient, in: Circle())

                Text(number)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.teal, in: Circle())
            }
            Text(title)
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
    }

    private var draftList: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                DraftInboxAnimation()
                    .frame(width: 84, height: 84)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Ready to review")
                        .font(.title3.bold())
                    Text("\(viewModel.drafts.count) shared draft\(viewModel.drafts.count == 1 ? "" : "s") waiting")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))

            ForEach(viewModel.drafts) { draft in
                draftCard(draft)
            }
        }
    }

    private func draftCard(_ draft: SharedReflectionDraft) -> some View {
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
            HStack(spacing: 14) {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Color.teal.gradient, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 6) {
                    Text(draft.suggestedText)
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                    Text(draft.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
