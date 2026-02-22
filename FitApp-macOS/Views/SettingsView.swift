import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var healthKitService = HealthKitService()

    @State private var mcpURL = ""
    @State private var apiKey = ""
    @State private var statusMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.largeTitle.bold())

            Form {
                TextField("MCP Server URL", text: $mcpURL)

                Picker("Theme", selection: $appState.selectedTheme) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                SecureField("OpenAI API Key (stored in Keychain)", text: $apiKey)

                HStack {
                    Button("Save Settings") {
                        appState.mcpServerURLString = mcpURL
                        appState.saveSettings()
                        statusMessage = "Settings updated."
                    }

                    Button("Save API Key") {
                        appState.saveOpenAIKey(apiKey)
                        statusMessage = appState.hasStoredAPIKey ? "API key saved to Keychain." : "Failed to store API key."
                    }
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

            Text(appState.hasStoredAPIKey ? "API key currently stored" : "No API key stored")
                .font(.caption)
                .foregroundStyle(appState.hasStoredAPIKey ? .green : .orange)
        }
        .padding(20)
        .onAppear {
            mcpURL = appState.mcpServerURLString
            apiKey = appState.loadOpenAIKey()
        }
    }
}
