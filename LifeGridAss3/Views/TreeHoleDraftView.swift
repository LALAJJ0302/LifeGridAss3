import SwiftUI

struct TreeHoleDraftView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TreeHoleDraftViewModel

    init(
        sourceEntry: LifeEntry,
        publishPost: PublishTreeHolePostUseCase
    ) {
        _viewModel = StateObject(
            wrappedValue: TreeHoleDraftViewModel(
                sourceEntry: sourceEntry,
                publishPost: publishPost
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.indigo.opacity(0.12),
                        Color.teal.opacity(0.07),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        privacyHeader
                        messageEditor
                        emotionPicker
                        consentCard
                        publishButton
                    }
                    .padding(20)
                    .padding(.top, 54)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Review public copy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(
                "Not published",
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

    private var privacyHeader: some View {
        HStack(spacing: 16) {
            PublicShareAnimation()
                .frame(width: 86, height: 86)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Your private entry stays private")
                    .font(.title3.bold())
                Text("Only this edited copy and emotional label can be published.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var messageEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Editable public copy", systemImage: "pencil.and.outline")
                .font(.headline)
                .foregroundStyle(.indigo)

            TextEditor(text: $viewModel.publicMessage)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
                .padding(12)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 16)
                )

            HStack {
                Label("Public draft", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.remainingCharacters) characters left")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(
                        viewModel.remainingCharacters < 0 ? .red : .secondary
                    )
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var emotionPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Public emotional label", systemImage: "heart.text.square.fill")
                .font(.headline)
                .foregroundStyle(.teal)

            Picker("Emotion", selection: $viewModel.emotionalState) {
                Text("Choose a label").tag(EmotionalState?.none)
                ForEach(EmotionalState.allCases) { state in
                    Text(state.rawValue.capitalized)
                        .tag(Optional(state))
                }
            }
            .pickerStyle(.menu)
            .tint(.indigo)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .background(
                Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var consentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(
                "I understand this edited copy will be public",
                isOn: $viewModel.hasConfirmedAnonymousSharing
            )
            .font(.headline)
            .tint(.teal)

            Divider()

            Label {
                Text(
                    "Your profile and private entry ID are never attached. "
                    + "Sexual or violent content is blocked."
                )
            } icon: {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.teal)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var publishButton: some View {
        Button {
            Task {
                if await viewModel.publish() {
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 9) {
                if viewModel.isPublishing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                }

                Text(
                    viewModel.isPublishing
                        ? "Publishing…"
                        : "Publish anonymously"
                )
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
        .disabled(!viewModel.canPublish)
    }
}
