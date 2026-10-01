import Foundation
import WidgetKit

/// Publishes a privacy-safe summary after relevant LifeGrid data changes.
enum LifeGridWidgetCoordinator {
    static func refresh(
        profile: UserProfile,
        hasReflectedThisWeek: Bool,
        now: Date = .now
    ) {
        let snapshot = LifeGridWidgetSnapshot(
            currentWeek: profile.weeksLived(asOf: now),
            remainingWeeks: profile.remainingWeeks(asOf: now),
            hasReflectedThisWeek: hasReflectedThisWeek,
            updatedAt: now
        )

        do {
            try AppGroupLifeGridWidgetStore().save(snapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: LifeGridAppGroup.widgetKind)
        } catch {
            // The app remains usable if App Group provisioning is unavailable.
            // The next successful refresh replaces this snapshot.
        }
    }
}
