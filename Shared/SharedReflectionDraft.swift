import Foundation

/// Text received from another app. It is not a LifeEntry until the person
/// reviews and explicitly imports it inside LifeGrid.
struct SharedReflectionDraft: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let suggestedText: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        suggestedText: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.suggestedText = suggestedText
        self.createdAt = createdAt
    }
}

struct AppGroupSharedReflectionDraftStore {
    private static let draftsKey = "sharedReflectionDrafts"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: LifeGridAppGroup.identifier)) {
        self.defaults = defaults
    }

    func append(_ draft: SharedReflectionDraft) throws {
        guard let defaults else {
            throw SharedReflectionDraftStoreError.appGroupUnavailable
        }

        var drafts = loadAll()
        drafts.removeAll { $0.id == draft.id }
        drafts.append(draft)
        let data = try JSONEncoder().encode(drafts)
        defaults.set(data, forKey: Self.draftsKey)
    }

    func loadAll() -> [SharedReflectionDraft] {
        guard
            let data = defaults?.data(forKey: Self.draftsKey),
            let drafts = try? JSONDecoder().decode(
                [SharedReflectionDraft].self,
                from: data
            )
        else {
            return []
        }

        return drafts.sorted { $0.createdAt > $1.createdAt }
    }

    func remove(id: SharedReflectionDraft.ID) throws {
        guard let defaults else {
            throw SharedReflectionDraftStoreError.appGroupUnavailable
        }

        let remaining = loadAll().filter { $0.id != id }
        let data = try JSONEncoder().encode(remaining)
        defaults.set(data, forKey: Self.draftsKey)
    }
}

enum SharedReflectionDraftStoreError: Error, Equatable {
    case appGroupUnavailable
}
