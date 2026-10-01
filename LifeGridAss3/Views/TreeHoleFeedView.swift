import SwiftUI

struct TreeHoleFeedView: View {
    @StateObject private var viewModel: TreeHoleFeedViewModel

    init(loadPosts: LoadTreeHoleFeedUseCase) {
        _viewModel = StateObject(
            wrappedValue: TreeHoleFeedViewModel(loadPosts: loadPosts)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    safetyHeader
                    emotionFilter

                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        ProgressView("Opening the Tree Hole…")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if let errorMessage = viewModel.errorMessage {
                        ContentUnavailableView {
                            Label("Tree Hole unavailable", systemImage: "wifi.exclamationmark")
                        } description: {
                            Text(errorMessage)
                        } actions: {
                            Button("Try again") {
                                Task { await viewModel.load() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else if viewModel.posts.isEmpty {
                        ContentUnavailableView(
                            "No posts found",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text("Try another emotion or return later.")
                        )
                    } else {
                        ForEach(viewModel.posts) { post in
                            postCard(post)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.teal.opacity(0.05))
            .navigationTitle("Tree Hole")
            .refreshable { await viewModel.load() }
        }
        .task(id: viewModel.selectedEmotion) {
            await viewModel.load()
        }
    }

    private var safetyHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Anonymous support space", systemImage: "person.2.wave.2.fill")
                .font(.headline)
                .foregroundStyle(.teal)
            Text("Respond with care. Public posts do not include LifeGrid profile details.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var emotionFilter: some View {
        Picker("Filter by emotion", selection: $viewModel.selectedEmotion) {
            Text("All emotions").tag(EmotionalState?.none)
            ForEach(EmotionalState.allCases) { emotion in
                Text(emotion.rawValue.capitalized).tag(Optional(emotion))
            }
        }
        .pickerStyle(.menu)
    }

    private func postCard(_ post: TreeHolePost) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    post.emotionalState.rawValue.capitalized,
                    systemImage: "heart.text.square"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.teal)

                Spacer()

                Text(post.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(post.message)
                .frame(maxWidth: .infinity, alignment: .leading)

            Label("Shared anonymously", systemImage: "eye.slash")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}
