import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var mcpServerURLString: String
    @Published var selectedTheme: ThemeMode
    @Published var latestTrendInsights: AnalyzeTrendsResponse?
    @Published var hasStoredAPIKey: Bool

    private let defaults: UserDefaults
    private let keychain: KeychainService

    static let mcpServerURLKey = "fitmind.settings.mcpServerURL"
    static let themeModeKey = "fitmind.settings.themeMode"
    static let defaultMCPServerURL = "http://127.0.0.1:8787"

    static let keychainService = "fitmind-ai-keys"
    static let openAIAccount = "openai-api-key"

    init(
        defaults: UserDefaults = .standard,
        keychain: KeychainService = KeychainService()
    ) {
        self.defaults = defaults
        self.keychain = keychain

        mcpServerURLString = defaults.string(forKey: Self.mcpServerURLKey) ?? Self.defaultMCPServerURL

        if let rawTheme = defaults.string(forKey: Self.themeModeKey),
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
        URL(string: mcpServerURLString) ?? URL(string: Self.defaultMCPServerURL)!
    }

    func saveSettings() {
        defaults.set(mcpServerURLString, forKey: Self.mcpServerURLKey)
        defaults.set(selectedTheme.rawValue, forKey: Self.themeModeKey)
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
