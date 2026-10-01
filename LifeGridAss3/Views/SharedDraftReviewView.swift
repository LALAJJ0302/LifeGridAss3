import SwiftUI

struct SharedDraftReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile
    let onImported: (SharedReflectionDraft) -> Void
    @StateObject private var viewModel: SharedDraftReviewViewModel

    init(
        profile: UserProfile,
        draft: SharedReflectionDraft,
        importDraft: ImportSharedReflectionDraftUseCase,
        onImported: @escaping (SharedReflectionDraft) -> Void
    ) {
        self.profile = profile
        self.onImported = onImported
        _viewModel = StateObject(
            wrappedValue: SharedDraftReviewViewModel(
                draft: draft,
                importDraft: importDraft
            )
        )
    }

    var body: some View {
        Form {
            Section("Review private reflection") {
                TextEditor(text: $viewModel.reviewedMessage)
                    .frame(minHeight: 180)

                Text("\(viewModel.remainingCharacters) characters remaining")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(
                        viewModel.remainingCharacters < 0 ? .red : .secondary
                    )
            }

            Section("Emotional label (optional)") {
                Picker("Emotion", selection: $viewModel.emotionalState) {
                    Text("No label").tag(EmotionalState?.none)
                    ForEach(EmotionalState.allCases) { emotion in
                        Text(emotion.rawValue.capitalized).tag(Optional(emotion))
                    }
                }
            }

            Section {
                Button {
                    Task {
                        if await viewModel.save(
                            lifeWeekNumber: profile.weeksLived()
                        ) != nil {
                            LifeGridWidgetCoordinator.refresh(
                                profile: profile,
                                hasReflectedThisWeek: true
                            )
                            onImported(viewModel.draft)
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isSaving { ProgressView() }
                        Text(viewModel.isSaving ? "Saving…" : "Save privately")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.canSave)
            } footer: {
                Text("This draft stays private. It is never published to the Tree Hole automatically.")
            }
        }
        .navigationTitle("Review shared draft")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Draft not saved",
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
