import Combine
import Foundation

@MainActor
final class SupportRepliesViewModel: ObservableObject {
    @Published var draft = ""
    @Published private(set) var replies: [SupportReply] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    private let postID: TreeHolePost.ID
    private let loadReplies: LoadSupportRepliesUseCase
    private let sendReply: SendSupportReplyUseCase

    init(
        postID: TreeHolePost.ID,
        loadReplies: LoadSupportRepliesUseCase,
        sendReply: SendSupportReplyUseCase
    ) {
        self.postID = postID
        self.loadReplies = loadReplies
        self.sendReply = sendReply
    }

    var remainingCharacters: Int {
        SendSupportReplyUseCase.maximumMessageLength - draft.count
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && remainingCharacters >= 0
            && !isSending
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            replies = try await loadReplies.execute(for: postID)
        } catch {
            errorMessage = "Replies could not be loaded from this device. Try again."
        }
    }

    func send() async {
        guard canSend else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }

        do {
            let reply = try await sendReply.execute(postID: postID, message: draft)
            replies.append(reply)
            replies.sort { $0.createdAt < $1.createdAt }
            draft = ""
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Your reply could not be sent."
        }
    }
}
