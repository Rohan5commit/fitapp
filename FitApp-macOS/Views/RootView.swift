import SwiftData
import SwiftUI

struct RootView: View {
    @Query(sort: \UserProfile.createdAt, order: .forward) private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                MainTabsView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .frame(minWidth: 980, minHeight: 700)
    }
}

private struct MainTabsView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            DashboardView(profile: profile)
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.grid.2x2")
                }

            PlanGeneratorView(profile: profile)
                .tabItem {
                    Label("Generator", systemImage: "wand.and.stars")
                }

            InsightsView(profile: profile)
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
