import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var viewModel: ProfileSetupViewModel
    @State private var displayedLifeYear: Int
    @State private var selectedWeek: SelectedLifeWeek?
    private let loadLifeEntries: LoadLifeEntriesForWeekUseCase?
    let onProfileCreated: (UserProfile) -> Void

    init(
        createProfile: CreateUserProfileUseCase,
        existingProfile: UserProfile? = nil,
        loadLifeEntries: LoadLifeEntriesForWeekUseCase? = nil,
        onProfileCreated: @escaping (UserProfile) -> Void
    ) {
        let previewProfile = existingProfile ?? UserProfile(
            birthDate: Calendar.current.date(
                byAdding: .year,
                value: -25,
                to: .now
            ) ?? .now
        )
        _viewModel = StateObject(
            wrappedValue: ProfileSetupViewModel(
                createProfile: createProfile,
                existingProfile: existingProfile
            )
        )
        _displayedLifeYear = State(
            initialValue: min(
                previewProfile.weeksLived() / 52,
                previewProfile.lifespanFrameYears - 1
            )
        )
        self.loadLifeEntries = loadLifeEntries
        self.onProfileCreated = onProfileCreated
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo.opacity(0.16), Color.teal.opacity(0.08), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    growthCard
                    lifeGridPreview
                    profileForm
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 36)
            }
        }
        .alert(
            "Profile not saved",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(item: $selectedWeek) { selection in
            LifeWeekDetailView(
                profile: currentProfile,
                lifeWeekNumber: selection.number,
                loadLifeEntries: loadLifeEntries
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var growthCard: some View {
        HStack(spacing: 16) {
            GrowingPlantAnimation()
                .frame(width: 120, height: 120)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Grow one week at a time")
                    .font(.headline)
                Text("Small reflections can become meaningful patterns over time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var header: some View {
        LifeGridPageHeader(
            context: viewModel.isEditing ? "Your time, your story" : "Begin here",
            title: viewModel.isEditing ? "Your Profile" : "Build your LifeGrid",
            subtitle: viewModel.isEditing
                ? "Shape the frame behind your personal LifeGrid."
                : "Turn time into a gentle reminder to live intentionally.",
            symbol: "person.crop.circle.fill",
            accent: .indigo
        )
    }

    private var lifeGridPreview: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    displayedLifeYear -= 1
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(displayedLifeYear == 0)

                Spacer()

                VStack(spacing: 3) {
                    Text("Life year \(displayedLifeYear + 1)")
                        .font(.headline)
                    Text(yearDateRange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    displayedLifeYear += 1
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(displayedLifeYear >= viewModel.lifespanFrameYears - 1)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 13),
                spacing: 5
            ) {
                ForEach(weeksInDisplayedYear, id: \.self) { week in
                    Button {
                        selectedWeek = SelectedLifeWeek(number: week)
                    } label: {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color(for: week))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if week == currentProfile.weeksLived() {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(.teal, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: week))
                }
            }

            HStack(spacing: 14) {
                gridLegend(color: .indigo, text: "Lived")
                gridLegend(color: .teal, text: "This week")
                gridLegend(color: .secondary.opacity(0.16), text: "Ahead")
            }
            .font(.caption)

            Text("Tap any week to see its dates and reflections.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var currentProfile: UserProfile {
        UserProfile(
            birthDate: viewModel.birthDate,
            lifespanFrameYears: viewModel.lifespanFrameYears
        )
    }

    private var weeksInDisplayedYear: Range<Int> {
        let firstWeek = displayedLifeYear * 52
        return firstWeek..<(firstWeek + 52)
    }

    private var yearDateRange: String {
        guard
            let firstDate = currentProfile.startDate(forLifeWeek: displayedLifeYear * 52),
            let lastDate = currentProfile.endDate(forLifeWeek: displayedLifeYear * 52 + 51)
        else { return "" }

        return "\(firstDate.formatted(date: .abbreviated, time: .omitted)) – \(lastDate.formatted(date: .abbreviated, time: .omitted))"
    }

    private func color(for week: Int) -> Color {
        let currentWeek = currentProfile.weeksLived()
        if week < currentWeek { return .indigo }
        if week == currentWeek { return .teal.opacity(0.55) }
        return .secondary.opacity(0.16)
    }

    private func accessibilityLabel(for week: Int) -> String {
        guard
            let start = currentProfile.startDate(forLifeWeek: week),
            let end = currentProfile.endDate(forLifeWeek: week)
        else { return "Life week \(week)" }

        return "Life week \(week), \(start.formatted(date: .long, time: .omitted)) to \(end.formatted(date: .long, time: .omitted))"
    }

    private func gridLegend(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .foregroundStyle(.secondary)
        }
    }

    private var profileForm: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your birth date")
                    .font(.headline)

                DatePicker(
                    "Birth date",
                    selection: $viewModel.birthDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)

                Label("Stored only on this device", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Stepper(value: $viewModel.lifespanFrameYears, in: 60...120) {
                    Text("Life frame: **\(viewModel.lifespanFrameYears) years**")
                }

                Text("This is a reflection frame, not a prediction of lifespan.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    if let profile = await viewModel.submit() {
                        onProfileCreated(profile)
                    }
                }
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .disabled(viewModel.isSaving)
        }
        .padding(22)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
    }

    private var buttonTitle: String {
        if viewModel.isSaving {
            return viewModel.isEditing ? "Saving changes…" : "Creating your grid…"
        }
        return viewModel.isEditing ? "Save profile changes" : "Create my LifeGrid"
    }
}

private struct SelectedLifeWeek: Identifiable {
    let number: Int
    var id: Int { number }
}

private struct LifeWeekDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile
    let lifeWeekNumber: Int
    let loadLifeEntries: LoadLifeEntriesForWeekUseCase?
    @State private var entries: [LifeEntry] = []
    @State private var loadErrorMessage: String?

    private var status: String {
        let currentWeek = profile.weeksLived()
        if lifeWeekNumber < currentWeek { return "Lived" }
        if lifeWeekNumber == currentWeek { return "Current week" }
        return "Future week"
    }

    private var statusColor: Color {
        switch status {
        case "Current week": .teal
        case "Lived": .indigo
        default: .secondary
        }
    }

    private var dateRange: String {
        guard
            let start = profile.startDate(forLifeWeek: lifeWeekNumber),
            let end = profile.endDate(forLifeWeek: lifeWeekNumber)
        else { return "Date unavailable" }

        return "\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.indigo.opacity(0.16),
                        Color.teal.opacity(0.09),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        weekHero
                        weekFacts

                        Text("Private reflections")
                            .font(.system(.title2, design: .rounded, weight: .bold))

                        reflectionContent
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                guard let loadLifeEntries else { return }
                do {
                    entries = try await loadLifeEntries.execute(
                        lifeWeekNumber: lifeWeekNumber
                    )
                } catch {
                    loadErrorMessage = (error as? LocalizedError)?.errorDescription
                        ?? "This week could not be opened."
                }
            }
        }
    }

    private var weekHero: some View {
        HStack(spacing: 16) {
            WeekPulseAnimation()
                .frame(width: 86, height: 86)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text("A moment in your story")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.indigo)
                Text("Week \(lifeWeekNumber.formatted())")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                Text(dateRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var weekFacts: some View {
        HStack(spacing: 12) {
            factCard(
                value: (lifeWeekNumber / 52 + 1).formatted(),
                label: "life year",
                color: .indigo
            )
            factCard(
                value: status,
                label: "timeline",
                color: statusColor
            )
        }
    }

    private func factCard(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var reflectionContent: some View {
        if loadLifeEntries == nil {
            messageCard(
                icon: "lock.fill",
                title: "Save your profile first",
                message: "Then reflections for this week can appear here."
            )
        } else if let loadErrorMessage {
            messageCard(
                icon: "exclamationmark.triangle.fill",
                title: "Week unavailable",
                message: loadErrorMessage
            )
        } else if entries.isEmpty {
            messageCard(
                icon: "moon.stars.fill",
                title: "A quiet week",
                message: "There is no private reflection saved for this week."
            )
        } else {
            VStack(spacing: 12) {
                ForEach(entries) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.teal)
                            .frame(width: 10, height: 10)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 7) {
                            Text(entry.message)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                Label("Private", systemImage: "lock.fill")
                                Spacer()
                                Text(entry.occurredAt.formatted(date: .omitted, time: .shortened))
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
    }

    private func messageCard(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.teal)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}
