import SwiftUI

struct QuickStatsView: View {
    @EnvironmentObject private var syncService: WatchSyncService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Stats")
                .font(.headline)
            Text("Calories: \(Int(syncService.caloriesToday))")
            Text("Streak: \(syncService.streak) days")
            Text("Next: \(syncService.nextSession)")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
    }
}
