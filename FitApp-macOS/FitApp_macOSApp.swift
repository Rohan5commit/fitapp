import SwiftData
import SwiftUI

@main
struct FitApp_macOSApp: App {
    @StateObject private var appState = AppState()

    private var sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([
                UserProfile.self,
                WorkoutPlan.self,
                WorkoutDay.self,
                Exercise.self,
                WorkoutLog.self,
                LoggedExercise.self
            ])
            let configuration = ModelConfiguration("FitAppStore")
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not initialize SwiftData container: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }

    private var preferredColorScheme: ColorScheme? {
        switch appState.selectedTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
