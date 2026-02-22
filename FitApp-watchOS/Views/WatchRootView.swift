import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject private var syncService: WatchSyncService

    var body: some View {
        TabView {
            ActiveWorkoutView()
            QuickStatsView()
            ComplicationPreviewView()
        }
        .tabViewStyle(.carousel)
    }
}
