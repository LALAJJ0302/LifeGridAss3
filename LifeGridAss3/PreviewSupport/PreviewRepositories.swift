#if DEBUG
import Foundation

/// In-memory storage for SwiftUI previews. It never touches saved app data,
/// so preview interactions are safe and repeatable.
actor PreviewLifeEntryRepository: LifeEntryRepository {
    private var storedEntries: [LifeEntry]

    init(entries: [LifeEntry] = []) {
        storedEntries = entries
    }

    func save(_ entry: LifeEntry) {
        storedEntries.removeAll { $0.id == entry.id }
        storedEntries.append(entry)
    }

    func update(_ entry: LifeEntry) {
        save(entry)
    }

    func entry(id: LifeEntry.ID) -> LifeEntry? {
        storedEntries.first { $0.id == id }
    }

    func entries(forLifeWeek week: Int) -> [LifeEntry] {
        storedEntries.filter { $0.lifeWeekNumber == week }
    }

}

/// In-memory public-post storage used only by interactive previews.
actor PreviewTreeHolePostRepository: TreeHolePostRepository {
    private var storedPosts: [TreeHolePost] = []

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
            .filter {
                $0.createdAt >= date
                    && (emotionalState == nil || $0.emotionalState == emotionalState)
            }
            .prefix(limit)
            .map { $0 }
    }
}
#endif
