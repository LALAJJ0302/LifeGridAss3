import SwiftUI

struct LifeGridHomeView: View {
    @Environment(\.scenePhase) private var scenePhase

    let profile: UserProfile
    let recordLifeEntry: RecordLifeEntryUseCase
    let publishTreeHolePost: PublishTreeHolePostUseCase
    @StateObject private var entriesViewModel: CurrentWeekEntriesViewModel
    @State private var entryForSharing: LifeEntry?

    init(
        profile: UserProfile,
        recordLifeEntry: RecordLifeEntryUseCase,
        loadLifeEntries: LoadLifeEntriesForWeekUseCase,
        publishTreeHolePost: PublishTreeHolePostUseCase
    ) {
        self.profile = profile
        self.recordLifeEntry = recordLifeEntry
        self.publishTreeHolePost = publishTreeHolePost
        _entriesViewModel = StateObject(
            wrappedValue: CurrentWeekEntriesViewModel(
                loadEntries: loadLifeEntries
            )
        )
    }

    private var currentWeek: Int {
        profile.weeksLived()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    LifeGridPageHeader(
                        context: "Private space",
                        title: "LifeGrid",
                        subtitle: "Notice this week. Keep what matters.",
                        symbol: "square.grid.3x3.fill",
                        accent: .indigo
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Week \(currentWeek.formatted())")
                            .font(.largeTitle.bold())
                        Text("One week at a time. Your private reflections belong to you.")
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 14) {
                        metricCard(
                            value: currentWeek.formatted(),
                            label: "weeks lived",
                            color: .indigo
                        )
                        metricCard(
                            value: profile.remainingWeeks().formatted(),
                            label: "weeks in frame",
                            color: .teal
                        )
                    }

                    PrivateReflectionEditorView(
                        recordLifeEntry: recordLifeEntry,
                        lifeWeekNumber: currentWeek,
                        onSaved: { entry in
                            entriesViewModel.entrySaved(entry)
                            LifeGridWidgetCoordinator.refresh(
                                profile: profile,
                                hasReflectedThisWeek: true
                            )
                        }
                    )

                    currentWeekEntries
                }
                .padding(20)
            }
            .refreshable {
                await reloadCurrentWeek()
            }
            .background(Color.indigo.opacity(0.05))
        }
        .task(id: currentWeek) {
            await reloadCurrentWeek()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            Task {
                await reloadCurrentWeek()
            }
        }
        .sheet(item: $entryForSharing) { entry in
            TreeHoleDraftView(
                sourceEntry: entry,
                publishPost: publishTreeHolePost
            )
        }
    }

    @MainActor
    private func reloadCurrentWeek() async {
        await entriesViewModel.load(lifeWeekNumber: currentWeek)
        LifeGridWidgetCoordinator.refresh(
            profile: profile,
            hasReflectedThisWeek: !entriesViewModel.entries.isEmpty
        )
    }

    @ViewBuilder
    private var currentWeekEntries: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This week's reflections")
                .font(.title2.bold())

            if entriesViewModel.isLoading && entriesViewModel.entries.isEmpty {
                ProgressView("Loading private reflections…")
            } else if entriesViewModel.entries.isEmpty {
                ContentUnavailableView(
                    "No reflections yet",
                    systemImage: "square.and.pencil",
                    description: Text("Your private entries for this week will appear here.")
                )
            } else {
                ForEach(entriesViewModel.entries) { entry in
                    reflectionCard(entry)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reflectionCard(_ entry: LifeEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let emotionalState = entry.emotionalState {
                    Label(
                        emotionalState.rawValue.capitalized,
                        systemImage: "heart.text.square"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
                } else {
                    Text("No emotional label")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(
                    entry.occurredAt.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            Text(entry.message)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Label("Private", systemImage: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Share edited copy") {
                    entryForSharing = entry
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private func metricCard(
        value: String,
        label: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}


#Preview {
    let profile = UserProfile(
        birthDate: .now.addingTimeInterval(-25 * 365 * 24 * 60 * 60),
        lifespanFrameYears: 80
    )
    let repository = try! SwiftDataLifeGridRepository(inMemory: true)

    LifeGridHomeView(
        profile: profile,
        recordLifeEntry: RecordLifeEntryUseCase(
            repository: repository
        ),
        loadLifeEntries: LoadLifeEntriesForWeekUseCase(
            repository: repository
        ),
        publishTreeHolePost: PublishTreeHolePostUseCase(
            repository: repository,
            safetyChecker: RuleBasedContentSafetyChecker()
        )
    )
}
