import Foundation
import AuthenticationServices
import Security
import Combine

/// Stubbed Notion OAuth service — ready for API key activation
@MainActor
class NotionService: ObservableObject {
    
    // MARK: - Configuration (Replace with real values)
    
    private let clientId = "YOUR_NOTION_CLIENT_ID"
    private let clientSecret = "YOUR_NOTION_CLIENT_SECRET"
    private let redirectUri = "awakened://notion-callback"
    
    // MARK: - Published State
    
    @Published var isConnected: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var authError: String?
    
    // MARK: - Keychain Keys
    
    private let accessTokenKey = "com.awakened.notion.accessToken"
    
    // MARK: - Initialization
    
    init() {
        isConnected = loadToken() != nil
    }
    
    // MARK: - OAuth Flow (Stubbed)
    
    /// Start the Notion OAuth flow
    func authenticate() {
        guard clientId != "YOUR_NOTION_CLIENT_ID" else {
            authError = "Notion API keys not configured yet. Coming soon!"
            return
        }
        
        isAuthenticating = true
        authError = nil
        
        let authURL = "https://api.notion.com/v1/oauth/authorize"
            + "?client_id=\(clientId)"
            + "&redirect_uri=\(redirectUri)"
            + "&response_type=code"
        
        guard let url = URL(string: authURL) else {
            authError = "Invalid auth URL"
            isAuthenticating = false
            return
        }
        
        // ASWebAuthenticationSession would go here
        // Stubbed for now
        print("NotionService: Would open OAuth URL — \(url)")
        isAuthenticating = false
        authError = "Notion integration coming soon"
    }
    
    /// Disconnect Notion
    func disconnect() {
        deleteToken()
        isConnected = false
    }
    
    // MARK: - Stubbed API Calls
    
    /// Fetch recent Notion pages (stubbed)
    func fetchRecentPages() async -> [String] {
        guard isConnected else { return [] }
        // Would call Notion API /v1/search
        return []
    }
    
    /// Fetch database entries (stubbed)
    func fetchDatabaseEntries() async -> [String] {
        guard isConnected else { return [] }
        // Would call Notion API /v1/databases/{id}/query
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
