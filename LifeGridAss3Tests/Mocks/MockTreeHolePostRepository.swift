import Foundation
@testable import LifeGridAss3

actor MockTreeHolePostRepository: TreeHolePostRepository {
    private var storedPosts: [TreeHolePost]

    init(posts: [TreeHolePost] = []) {
        storedPosts = posts
    }

    func publish(_ post: TreeHolePost) {
        storedPosts.append(post)
    }

    func post(id: TreeHolePost.ID) -> TreeHolePost? {
        storedPosts.first { $0.id == id }
    }

    func recentPosts(
        matching emotionalState: EmotionalState?,
        since date: Date,
        limit: Int
    ) -> [TreeHolePost] {
        storedPosts
            .filter { post in
                post.createdAt >= date
                    && (emotionalState == nil || post.emotionalState == emotionalState)
            }
            .prefix(limit)
            .map { $0 }
    }

    func publishedPosts() -> [TreeHolePost] {
        storedPosts
    }
}
