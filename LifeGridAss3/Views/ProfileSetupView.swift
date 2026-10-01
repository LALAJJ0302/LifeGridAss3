import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var viewModel: ProfileSetupViewModel
    let onProfileCreated: (UserProfile) -> Void

    init(
        createProfile: CreateUserProfileUseCase,
        onProfileCreated: @escaping (UserProfile) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: ProfileSetupViewModel(createProfile: createProfile)
        )
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
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 42))
                .foregroundStyle(.indigo)

            Text("Build your LifeGrid")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Turn time into a gentle visual reminder to notice, reflect, and live intentionally.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var lifeGridPreview: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 12),
            spacing: 5
        ) {
            ForEach(0..<72, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < 23 ? Color.indigo : Color.secondary.opacity(0.16))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityLabel("A preview of the LifeGrid")
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

                Label("Stored only in your private iCloud database", systemImage: "lock.fill")
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
                    Text(viewModel.isSaving ? "Creating your grid…" : "Create my LifeGrid")
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
}
