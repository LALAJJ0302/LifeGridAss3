import Combine
import Foundation

@MainActor
final class TreeHoleFeedViewModel: ObservableObject {
    @Published var selectedEmotion: EmotionalState?
    @Published private(set) var posts: [TreeHolePost] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let loadPosts: LoadTreeHoleFeedUseCase

    init(loadPosts: LoadTreeHoleFeedUseCase) {
        self.loadPosts = loadPosts
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            posts = try await loadPosts.execute(matching: selectedEmotion)
        } catch {
            posts = []
            errorMessage = "The local Tree Hole could not be loaded. Try again."
        }
    }
}
