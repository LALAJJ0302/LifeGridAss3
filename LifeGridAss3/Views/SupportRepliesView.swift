import SwiftUI

struct SupportRepliesView: View {
    let post: TreeHolePost
    @StateObject private var viewModel: SupportRepliesViewModel

    init(
        post: TreeHolePost,
        loadReplies: LoadSupportRepliesUseCase,
        sendReply: SendSupportReplyUseCase
    ) {
        self.post = post
        _viewModel = StateObject(
            wrappedValue: SupportRepliesViewModel(
                postID: post.id,
                loadReplies: loadReplies,
                sendReply: sendReply
            )
        )
    }

    var body: some View {
        List {
            Section("Anonymous post") {
                Text(post.message)
                Label(
                    post.emotionalState.rawValue.capitalized,
                    systemImage: "heart.text.square"
                )
                .font(.caption)
                .foregroundStyle(.teal)
            }

            Section("Supportive replies") {
                if viewModel.isLoading && viewModel.replies.isEmpty {
                    ProgressView("Loading replies…")
                } else if viewModel.replies.isEmpty {
                    ContentUnavailableView(
                        "No replies yet",
                        systemImage: "heart.bubble",
                        description: Text("Be the first person to respond with care.")
                    )
                } else {
                    ForEach(viewModel.replies) { reply in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(reply.message)
                            Text(reply.createdAt.formatted(.relative(presentation: .named)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                TextField(
                    "A kind, supportive reply",
                    text: $viewModel.draft,
                    axis: .vertical
                )
                .lineLimit(3...6)

                HStack {
                    Text("\(viewModel.remainingCharacters) characters remaining")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(
                            viewModel.remainingCharacters < 0 ? .red : .secondary
                        )
                    Spacer()
                    Button(viewModel.isSending ? "Sending…" : "Send anonymously") {
                        Task { await viewModel.send() }
                    }
                    .disabled(!viewModel.canSend)
                }
            } header: {
                Text("Write support")
            } footer: {
                Text("Replies are public. Sexual or violent content is blocked.")
            }
        }
        .navigationTitle("Send support")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert(
            "Reply unavailable",
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
