import SwiftData
import SwiftUI
import AuthenticationServices

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @Query(sort: \UserProfile.createdAt, order: .forward) private var profiles: [UserProfile]

    var body: some View {
        Group {
            if !appState.isLocallyAuthenticated {
                LocalAuthGateView()
            } else {
                if let profile = profiles.first {
                    MainTabsView(profile: profile)
                } else {
                    OnboardingView()
                }
            }
        }
        .frame(minWidth: 980, minHeight: 700)
    }
}

private struct LocalAuthGateView: View {
    @EnvironmentObject private var appState: AppState
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 18) {
            Text("FitMind")
                .font(.largeTitle.bold())

            Text("Sign in with Apple to continue.")
                .foregroundStyle(.secondary)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case let .success(authorization):
                    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                        errorMessage = "Could not read Apple ID credential."
                        return
                    }
                    appState.completeLocalAppleSignIn(userIdentifier: credential.user)
                    errorMessage = ""
                case let .failure(error):
                    errorMessage = "Sign in failed: \(error.localizedDescription)"
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(width: 280, height: 44)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
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
