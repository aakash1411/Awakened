import Foundation
import AuthenticationServices
import Security
import Combine

/// Stubbed GitHub OAuth service — ready for API key activation
@MainActor
class GitHubService: ObservableObject {
    
    // MARK: - Configuration (Replace with real values)
    
    private let clientId = "YOUR_GITHUB_CLIENT_ID"
    private let clientSecret = "YOUR_GITHUB_CLIENT_SECRET"
    private let redirectUri = "awakened://github-callback"
    private let scope = "repo,read:user"
    
    // MARK: - Published State
    
    @Published var isConnected: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var authError: String?
    
    // MARK: - Keychain Keys
    
    private let accessTokenKey = "com.awakened.github.accessToken"
    
    // MARK: - Initialization
    
    init() {
        isConnected = loadToken() != nil
    }
    
    // MARK: - OAuth Flow (Stubbed)
    
    /// Start the GitHub OAuth flow
    func authenticate() {
        guard clientId != "YOUR_GITHUB_CLIENT_ID" else {
            authError = "GitHub API keys not configured yet. Coming soon!"
            return
        }
        
        isAuthenticating = true
        authError = nil
        
        let authURL = "https://github.com/login/oauth/authorize"
            + "?client_id=\(clientId)"
            + "&redirect_uri=\(redirectUri)"
            + "&scope=\(scope)"
        
        guard let url = URL(string: authURL) else {
            authError = "Invalid auth URL"
            isAuthenticating = false
            return
        }
        
        // ASWebAuthenticationSession would go here
        // Stubbed for now
        print("GitHubService: Would open OAuth URL — \(url)")
        isAuthenticating = false
        authError = "GitHub integration coming soon"
    }
    
    /// Disconnect GitHub
    func disconnect() {
        deleteToken()
        isConnected = false
    }
    
    // MARK: - Stubbed API Calls
    
    /// Fetch recent commits (stubbed)
    func fetchRecentCommits() async -> [String] {
        guard isConnected else { return [] }
        // Would call GitHub API /user/repos then /repos/{owner}/{repo}/commits
        return []
    }
    
    /// Fetch contribution data (stubbed)
    func fetchContributions() async -> [String] {
        guard isConnected else { return [] }
        // Would call GitHub GraphQL API for contribution calendar
        return []
    }
    
    // MARK: - Keychain
    
    private func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accessTokenKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accessTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accessTokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}
