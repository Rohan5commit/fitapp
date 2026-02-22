import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var mcpServerURLString: String
    @Published var selectedTheme: ThemeMode
    @Published var latestTrendInsights: AnalyzeTrendsResponse?
    @Published var hasStoredAPIKey: Bool

    private let defaults = UserDefaults.standard
    private let keychain = KeychainService()

    private let mcpServerURLKey = "fitmind.settings.mcpServerURL"
    private let themeModeKey = "fitmind.settings.themeMode"

    static let keychainService = "fitmind-ai-keys"
    static let openAIAccount = "openai-api-key"

    init() {
        mcpServerURLString = defaults.string(forKey: mcpServerURLKey) ?? "http://127.0.0.1:8787"
        if let rawTheme = defaults.string(forKey: themeModeKey),
           let theme = ThemeMode(rawValue: rawTheme) {
            selectedTheme = theme
        } else {
            selectedTheme = .system
        }

        if let saved = try? keychain.read(service: Self.keychainService, account: Self.openAIAccount),
           !saved.isEmpty {
            hasStoredAPIKey = true
        } else {
            hasStoredAPIKey = false
        }
    }

    var mcpServerURL: URL {
        URL(string: mcpServerURLString) ?? URL(string: "http://127.0.0.1:8787")!
    }

    func saveSettings() {
        defaults.set(mcpServerURLString, forKey: mcpServerURLKey)
        defaults.set(selectedTheme.rawValue, forKey: themeModeKey)
    }

    func loadOpenAIKey() -> String {
        (try? keychain.read(service: Self.keychainService, account: Self.openAIAccount)) ?? ""
    }

    func saveOpenAIKey(_ value: String) {
        do {
            try keychain.save(value: value, service: Self.keychainService, account: Self.openAIAccount)
            hasStoredAPIKey = !value.isEmpty
        } catch {
            hasStoredAPIKey = false
        }
    }
}
