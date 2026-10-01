import Foundation
import Testing
@testable import LifeGridAss3

struct AppGroupSharedReflectionDraftStoreTests {
    @Test("The Share Extension inbox appends and removes drafts")
    func draftRoundTrip() throws {
        let suiteName = "LifeGridShareStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let store = AppGroupSharedReflectionDraftStore(defaults: defaults)
        let older = SharedReflectionDraft(
            suggestedText: "Older",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newer = SharedReflectionDraft(
            suggestedText: "Newer",
            createdAt: Date(timeIntervalSince1970: 200)
        )

        try store.append(older)
        try store.append(newer)
        #expect(store.loadAll() == [newer, older])

        try store.remove(id: older.id)
        #expect(store.loadAll() == [newer])
    }
}
