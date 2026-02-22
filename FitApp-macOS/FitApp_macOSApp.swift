import SwiftData
import SwiftUI

@main
struct FitApp_macOSApp: App {
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            WorkoutPlan.self,
            WorkoutDay.self,
            Exercise.self,
            WorkoutLog.self,
            LoggedExercise.self
        ])
        let configuration = ModelConfiguration("FitAppStore")
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
