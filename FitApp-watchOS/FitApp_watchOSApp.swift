import SwiftUI

@main
struct FitApp_watchOSApp: App {
    @StateObject private var syncService = WatchSyncService()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(syncService)
        }
    }
}
