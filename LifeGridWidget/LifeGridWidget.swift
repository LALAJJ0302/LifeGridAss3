import SwiftUI
import WidgetKit

struct LifeGridWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: LifeGridWidgetSnapshot?
}

struct LifeGridWidgetProvider: TimelineProvider {
    private let store = AppGroupLifeGridWidgetStore()

    func placeholder(in context: Context) -> LifeGridWidgetEntry {
        LifeGridWidgetEntry(date: .now, snapshot: Self.sampleSnapshot)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (LifeGridWidgetEntry) -> Void
    ) {
        completion(
            LifeGridWidgetEntry(
                date: .now,
                snapshot: context.isPreview ? Self.sampleSnapshot : store.load()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<LifeGridWidgetEntry>) -> Void
    ) {
        let now = Date()
        let entry = LifeGridWidgetEntry(date: now, snapshot: store.load())
        let nextRefresh = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3_600)

        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private static let sampleSnapshot = LifeGridWidgetSnapshot(
        currentWeek: 1_303,
        remainingWeeks: 2_857,
        hasReflectedThisWeek: true,
        updatedAt: .now
    )
}

struct LifeGridWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LifeGridWidgetEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                switch family {
                case .accessoryRectangular:
                    lockScreenView(snapshot)
                default:
                    homeScreenView(snapshot)
                }
            } else {
                unavailableView
            }
        }
        .containerBackground(.indigo.gradient, for: .widget)
    }

    private func homeScreenView(_ snapshot: LifeGridWidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("LifeGrid", systemImage: "square.grid.3x3.fill")
                .font(.caption.weight(.semibold))

            Text("Week \(snapshot.currentWeek.formatted())")
                .font(.title2.bold())
                .minimumScaleFactor(0.75)

            Text(
                snapshot.hasReflectedThisWeek
                    ? "Reflection saved this week"
                    : "A moment to reflect"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text("\(snapshot.remainingWeeks.formatted()) weeks in frame")
                .font(.caption2.monospacedDigit())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func lockScreenView(_ snapshot: LifeGridWidgetSnapshot) -> some View {
        HStack(spacing: 8) {
            Image(systemName: snapshot.hasReflectedThisWeek ? "checkmark.circle.fill" : "heart.text.square")
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("LifeGrid · Week \(snapshot.currentWeek.formatted())")
                    .font(.headline)
                Text(snapshot.hasReflectedThisWeek ? "Reflected this week" : "Take a quiet moment")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var unavailableView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "square.grid.3x3.fill")
            Text("Open LifeGrid")
                .font(.headline)
            Text("Your private summary will appear here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct LifeGridWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: LifeGridAppGroup.widgetKind,
            provider: LifeGridWidgetProvider()
        ) { entry in
            LifeGridWidgetView(entry: entry)
        }
        .configurationDisplayName("LifeGrid Week")
        .description("See your current life week and weekly reflection status.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

#Preview("Home Screen", as: .systemSmall) {
    LifeGridWidget()
} timeline: {
    LifeGridWidgetEntry(
        date: .now,
        snapshot: LifeGridWidgetSnapshot(
            currentWeek: 1_303,
            remainingWeeks: 2_857,
            hasReflectedThisWeek: true,
            updatedAt: .now
        )
    )
}

#Preview("Lock Screen", as: .accessoryRectangular) {
    LifeGridWidget()
} timeline: {
    LifeGridWidgetEntry(
        date: .now,
        snapshot: LifeGridWidgetSnapshot(
            currentWeek: 1_303,
            remainingWeeks: 2_857,
            hasReflectedThisWeek: false,
            updatedAt: .now
        )
    )
}
