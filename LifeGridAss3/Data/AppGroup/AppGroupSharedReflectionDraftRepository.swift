import Foundation

actor AppGroupSharedReflectionDraftRepository: SharedReflectionDraftRepository {
    private let store: AppGroupSharedReflectionDraftStore

    init(store: AppGroupSharedReflectionDraftStore = .init()) {
        self.store = store
    }

    func drafts() -> [SharedReflectionDraft] {
        store.loadAll()
    }

    func remove(id: SharedReflectionDraft.ID) throws {
        try store.remove(id: id)
    }
}
