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
        ZStack {
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.10),
                    Color.teal.opacity(0.08),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    welcomeCard
                    postCard
                    repliesSection
                    composerCard
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .refreshable { await viewModel.load() }
        }
        .navigationTitle("Send support")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .animation(.spring(duration: 0.35), value: viewModel.replies.count)
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

    private var welcomeCard: some View {
        HStack(spacing: 16) {
            SupportPulseAnimation()
                .frame(width: 82, height: 82)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text("Someone is listening")
                    .font(.title3.bold())
                Text("A few kind words can make this moment feel less lonely.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var postCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Anonymous post", systemImage: "eye.slash.fill")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(post.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text("“\(post.message)”")
                .font(.title3.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            Label(
                post.emotionalState.rawValue.capitalized,
                systemImage: "heart.text.square.fill"
            )
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(0.65), in: Capsule())
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.teal.opacity(0.24),
                            Color.indigo.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    @ViewBuilder
    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Supportive replies")
                    .font(.title2.bold())
                Spacer()
                Text("\(viewModel.replies.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.indigo.opacity(0.12), in: Capsule())
            }

            if viewModel.isLoading && viewModel.replies.isEmpty {
                ProgressView("Loading replies…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else if viewModel.replies.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.teal)
                    Text("No replies yet")
                        .font(.headline)
                    Text("You can be the first person to respond with care.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            } else {
                ForEach(viewModel.replies) { reply in
                    replyBubble(reply)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func replyBubble(_ reply: SupportReply) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color.teal.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 7) {
                Text(reply.message)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(reply.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(15)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

            Spacer(minLength: 26)
        }
    }

    private var composerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Write something kind", systemImage: "pencil.and.scribble")
                .font(.headline)
                .foregroundStyle(.indigo)

            TextField(
                "A kind, supportive reply",
                text: $viewModel.draft,
                axis: .vertical
            )
            .lineLimit(3...6)
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

            HStack {
                Text("\(viewModel.remainingCharacters) left")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(
                        viewModel.remainingCharacters < 0 ? .red : .secondary
                    )

                Spacer()

                Button {
                    Task { await viewModel.send() }
                } label: {
                    HStack(spacing: 7) {
                        if viewModel.isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text(viewModel.isSending ? "Sending…" : "Send support")
                    }
                    .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(!viewModel.canSend)
            }

            Label(
                "Replies are public. Sexual or violent content is blocked.",
                systemImage: "shield.checkered"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}
