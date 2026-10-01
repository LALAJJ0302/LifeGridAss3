import SwiftUI

struct LifeGridHomeView: View {
    let profile: UserProfile
    let recordLifeEntry: RecordLifeEntryUseCase

    private var currentWeek: Int {
        profile.weeksLived()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Week \(currentWeek.formatted())")
                            .font(.largeTitle.bold())
                        Text("One week at a time. Your private reflections belong to you.")
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 14) {
                        metricCard(
                            value: currentWeek.formatted(),
                            label: "weeks lived",
                            color: .indigo
                        )
                        metricCard(
                            value: profile.remainingWeeks().formatted(),
                            label: "weeks in frame",
                            color: .teal
                        )
                    }

                    PrivateReflectionEditorView(
                        recordLifeEntry: recordLifeEntry,
                        lifeWeekNumber: currentWeek
                    )
                }
                .padding(20)
            }
            .background(Color.indigo.opacity(0.05))
            .navigationTitle("LifeGrid")
        }
    }

    private func metricCard(
        value: String,
        label: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}
