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
            Form {
                Section("Editable public copy") {
                    TextEditor(text: $viewModel.publicMessage)
                        .frame(minHeight: 160)

                    Text("\(viewModel.remainingCharacters) characters remaining")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(
                            viewModel.remainingCharacters < 0 ? .red : .secondary
                        )
                }

                Section("Public emotional label") {
                    Picker("Emotion", selection: $viewModel.emotionalState) {
                        Text("Choose a label").tag(EmotionalState?.none)
                        ForEach(EmotionalState.allCases) { state in
                            Text(state.rawValue.capitalized)
                                .tag(Optional(state))
                        }
                    }
                }

                Section {
                    Toggle(
                        "I understand this edited copy will be public",
                        isOn: $viewModel.hasConfirmedAnonymousSharing
                    )
                } footer: {
                    Text(
                        "LifeGrid does not attach your profile or private entry ID. "
                        + "Sexual or violent content is blocked from public sharing."
                    )
                }

                Section {
                    Button {
                        Task {
                            if await viewModel.publish() {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isPublishing {
                                ProgressView()
                            }
                            Text(
                                viewModel.isPublishing
                                    ? "Publishing…"
                                    : "Publish anonymously"
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!viewModel.canPublish)
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
}
