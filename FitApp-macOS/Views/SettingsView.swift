import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var healthKitService = HealthKitService()

    @State private var mcpURL = ""
    @State private var openAIKey = ""
    @State private var claudeKey = ""
    @State private var statusMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.largeTitle.bold())

            Form {
                TextField("MCP Server URL", text: $mcpURL)

                Picker("AI Provider", selection: $appState.selectedAIProvider) {
                    ForEach(AIProviderChoice.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                Picker("Theme", selection: $appState.selectedTheme) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Toggle("Sync New Logs To HealthKit", isOn: $appState.syncLogsToHealthKit)

                SecureField("OpenAI API Key (stored in Keychain)", text: $openAIKey)
                Button("Save OpenAI Key") {
                    appState.saveKey(openAIKey, for: .openai)
                    statusMessage = "OpenAI key saved."
                }

                SecureField("Claude API Key (stored in Keychain)", text: $claudeKey)
                Button("Save Claude Key") {
                    appState.saveKey(claudeKey, for: .claude)
                    statusMessage = "Claude key saved."
                }

                HStack {
                    Button("Save Settings") {
                        appState.mcpServerURLString = mcpURL
                        appState.saveSettings()
                        statusMessage = "Settings updated."
                    }
                }

                Button("Sign Out (Apple)") {
                    appState.signOutLocalUser()
                    statusMessage = "Signed out locally."
                }

                Button("Request HealthKit Permission") {
                    Task {
                        do {
                            try await healthKitService.requestAuthorization()
                            statusMessage = "HealthKit access granted."
                        } catch {
                            statusMessage = "HealthKit request failed: \(error.localizedDescription)"
                        }
                    }
                }
            }

            Text(statusMessage)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(appState.hasStoredKey(for: .openai) ? "OpenAI key stored" : "OpenAI key not stored")
                    .foregroundStyle(appState.hasStoredKey(for: .openai) ? .green : .orange)
                Text(appState.hasStoredKey(for: .claude) ? "Claude key stored" : "Claude key not stored")
                    .foregroundStyle(appState.hasStoredKey(for: .claude) ? .green : .orange)
                Text(appState.appleUserIdentifier == nil ? "Apple sign-in not active" : "Apple sign-in active")
                    .foregroundStyle(appState.appleUserIdentifier == nil ? .orange : .green)
            }
            .font(.caption)
        }
        .padding(20)
        .onAppear {
            mcpURL = appState.mcpServerURLString
            openAIKey = appState.loadKey(for: .openai)
            claudeKey = appState.loadKey(for: .claude)
        }
    }
}
