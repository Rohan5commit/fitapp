import SwiftUI

struct ComplicationPreviewView: View {
    @EnvironmentObject private var syncService: WatchSyncService

    private var headline: String {
        if let workout = syncService.todayWorkout {
            return workout.exercises.first?.name ?? "Workout Ready"
        }
        return "No Workout"
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
            Text("Today")
                .font(.caption)
            Text(headline)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }
}
