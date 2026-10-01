import Foundation
import Testing
@testable import LifeGridAss3

struct AppGroupLifeGridWidgetStoreTests {
    @Test("The widget receives only the privacy-safe weekly summary")
    func snapshotRoundTrips() throws {
        let suiteName = "LifeGridWidgetStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        let expected = LifeGridWidgetSnapshot(
            currentWeek: 1_303,
            remainingWeeks: 2_857,
            hasReflectedThisWeek: true,
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let store = AppGroupLifeGridWidgetStore(defaults: defaults)

        try store.save(expected)

        #expect(store.load() == expected)
    }
}
