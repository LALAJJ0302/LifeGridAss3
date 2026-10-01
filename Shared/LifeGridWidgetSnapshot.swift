import Foundation

/// The only LifeGrid data shared with system extensions.
/// Private reflection text and profile identifiers are intentionally excluded.
struct LifeGridWidgetSnapshot: Codable, Equatable, Sendable {
    let currentWeek: Int
    let remainingWeeks: Int
    let hasReflectedThisWeek: Bool
    let updatedAt: Date
}

enum LifeGridAppGroup {
    static let identifier = "group.LALAJJ0302.com.LifeGridAss3"
    static let widgetKind = "LifeGridWidget"
}

struct AppGroupLifeGridWidgetStore {
    private static let snapshotKey = "lifeGridWidgetSnapshot"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: LifeGridAppGroup.identifier)) {
        self.defaults = defaults
    }

    func save(_ snapshot: LifeGridWidgetSnapshot) throws {
        guard let defaults else {
            throw LifeGridWidgetStoreError.appGroupUnavailable
        }

        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: Self.snapshotKey)
    }

    func load() -> LifeGridWidgetSnapshot? {
        guard
            let data = defaults?.data(forKey: Self.snapshotKey),
            let snapshot = try? JSONDecoder().decode(
                LifeGridWidgetSnapshot.self,
                from: data
            )
        else {
            return nil
        }

        return snapshot
    }
}

enum LifeGridWidgetStoreError: Error, Equatable {
    case appGroupUnavailable
}
