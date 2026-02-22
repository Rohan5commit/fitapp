import Foundation

enum AIProviderChoice: String, CaseIterable, Identifiable {
    case openai
    case claude
    case mock

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai:
            return "OpenAI"
        case .claude:
            return "Claude"
        case .mock:
            return "Mock"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var mcpServerURLString: String
    @Published var selectedTheme: ThemeMode
    @Published var selectedAIProvider: AIProviderChoice
    @Published var latestTrendInsights: AnalyzeTrendsResponse?

    private let defaults: UserDefaults
    private let keychain: KeychainService

    static let mcpServerURLKey = "fitmind.settings.mcpServerURL"
    static let themeModeKey = "fitmind.settings.themeMode"
    static let providerKey = "fitmind.settings.aiProvider"
    static let defaultMCPServerURL = "http://127.0.0.1:8787"

    static let keychainService = "fitmind-ai-keys"
    static let openAIAccount = "openai-api-key"
    static let claudeAccount = "claude-api-key"

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

        if let rawProvider = defaults.string(forKey: Self.providerKey),
           let provider = AIProviderChoice(rawValue: rawProvider) {
            selectedAIProvider = provider
        } else {
            selectedAIProvider = .openai
        }
    }

    var mcpServerURL: URL {
        URL(string: mcpServerURLString) ?? URL(string: Self.defaultMCPServerURL)!
    }

    func saveSettings() {
        defaults.set(mcpServerURLString, forKey: Self.mcpServerURLKey)
        defaults.set(selectedTheme.rawValue, forKey: Self.themeModeKey)
        defaults.set(selectedAIProvider.rawValue, forKey: Self.providerKey)
    }

    func loadKey(for provider: AIProviderChoice) -> String {
        let account = keychainAccount(for: provider)
        return (try? keychain.read(service: Self.keychainService, account: account)) ?? ""
    }

    func saveKey(_ value: String, for provider: AIProviderChoice) {
        let account = keychainAccount(for: provider)

        do {
            try keychain.save(value: value, service: Self.keychainService, account: account)
        } catch {
            return
        }
    }

    func hasStoredKey(for provider: AIProviderChoice) -> Bool {
        !loadKey(for: provider).isEmpty
    }

    func mcpRequestHeaders() -> [String: String] {
        var headers: [String: String] = [
            "x-fitmind-provider": selectedAIProvider.rawValue
        ]

        switch selectedAIProvider {
        case .openai:
            let key = loadKey(for: .openai)
            if !key.isEmpty {
                headers["x-fitmind-openai-key"] = key
            }
        case .claude:
            let key = loadKey(for: .claude)
            if !key.isEmpty {
                headers["x-fitmind-anthropic-key"] = key
            }
        case .mock:
            break
        }

        return headers
    }

    private func keychainAccount(for provider: AIProviderChoice) -> String {
        switch provider {
        case .openai:
            return Self.openAIAccount
        case .claude:
            return Self.claudeAccount
        case .mock:
            return Self.openAIAccount
        }
    }
}
