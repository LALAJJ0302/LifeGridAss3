import SwiftUI

struct PrivateReflectionEditorView: View {
    @StateObject private var viewModel: LifeEntryEditorViewModel
    let lifeWeekNumber: Int
    let onSaved: (LifeEntry) -> Void

    init(
        recordLifeEntry: RecordLifeEntryUseCase,
        lifeWeekNumber: Int,
        onSaved: @escaping (LifeEntry) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: LifeEntryEditorViewModel(
                recordLifeEntry: recordLifeEntry
            )
        )
        self.lifeWeekNumber = lifeWeekNumber
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Private reflection")
                        .font(.title2.bold())
                    Text("What feels important right now?")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .foregroundStyle(.indigo)
                    .accessibilityLabel("Private")
            }

            TextEditor(text: $viewModel.message)
                .frame(minHeight: 130)
                .padding(10)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .bottomTrailing) {
                    Text("\(viewModel.remainingCharacters)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(
                            viewModel.remainingCharacters < 0 ? .red : .secondary
                        )
                        .padding(10)
                }

            VStack(alignment: .leading, spacing: 10) {
                Text("Emotional label (optional)")
                    .font(.subheadline.weight(.semibold))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        emotionButton(nil, title: "No label")

                        ForEach(EmotionalState.allCases) { state in
                            emotionButton(
                                state,
                                title: state.rawValue.capitalized
                            )
                        }
                    }
                }
            }

            Button {
                Task {
                    if let entry = await viewModel.save(
                        lifeWeekNumber: lifeWeekNumber
                    ) {
                        onSaved(entry)
                    }
                }
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isSaving ? "Saving…" : "Save privately")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .disabled(!viewModel.canSave)

            if let savedMessage = viewModel.savedMessage {
                Label(savedMessage, systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)
            }
        }
        .padding(22)
        .background(.background, in: RoundedRectangle(cornerRadius: 22))
        .alert(
            "Reflection not saved",
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

    private func emotionButton(
        _ state: EmotionalState?,
        title: String
    ) -> some View {
        Button(title) {
            viewModel.emotionalState = state
        }
        .buttonStyle(.bordered)
        .tint(viewModel.emotionalState == state ? .indigo : .secondary)
        .accessibilityAddTraits(
            viewModel.emotionalState == state ? .isSelected : []
        )
    }
}
