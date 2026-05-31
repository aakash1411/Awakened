import Foundation
import AuthenticationServices
import Security
import Combine

/// Strava API v3 activity response model
struct StravaActivity: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let sportType: String?
    let distance: Double
    let movingTime: Int
    let elapsedTime: Int
    let startDate: String
    let startDateLocal: String
    let averageSpeed: Double?
    let maxSpeed: Double?
    let averageHeartrate: Double?
    let maxHeartrate: Double?
    let hasHeartrate: Bool?
    let totalElevationGain: Double?
    let calories: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, distance, calories
        case sportType = "sport_type"
        case movingTime = "moving_time"
        case elapsedTime = "elapsed_time"
        case startDate = "start_date"
        case startDateLocal = "start_date_local"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case averageHeartrate = "average_heartrate"
        case maxHeartrate = "max_heartrate"
        case hasHeartrate = "has_heartrate"
        case totalElevationGain = "total_elevation_gain"
    }
}

/// Strava OAuth token response
private struct StravaTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case tokenType = "token_type"
    }
}

/// Stubbed Strava OAuth + API service
/// Full OAuth flow implemented; API calls return empty until real keys are provided
@MainActor
class StravaService: ObservableObject {
    
    // MARK: - Configuration
    
    // TODO: Replace with your Strava API application credentials
    private let clientId = "YOUR_STRAVA_CLIENT_ID"
    private let clientSecret = "YOUR_STRAVA_CLIENT_SECRET"
    private let redirectUri = "awakened://strava-callback"
    private let authURL = "https://www.strava.com/oauth/mobile/authorize"
    private let tokenURL = "https://www.strava.com/oauth/token"
    private let baseAPIURL = "https://www.strava.com/api/v3"
    
    // MARK: - Keychain Keys
    
    private let accessTokenKey = "strava_access_token"
    private let refreshTokenKey = "strava_refresh_token"
    private let expiresAtKey = "strava_expires_at"
    
    // MARK: - Published State
    
    @Published var isConnected: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var authError: String?
    
    // MARK: - Initialization
    
    init() {
        isConnected = getKeychainValue(key: accessTokenKey) != nil
    }
    
    // MARK: - Authentication
    
    /// Start the Strava OAuth flow using ASWebAuthenticationSession
    /// - Parameter presentationContext: The window to present the auth sheet in
    func authenticate(presentationContext: ASWebAuthenticationPresentationContextProviding) async throws {
        isAuthenticating = true
        authError = nil
        defer { isAuthenticating = false }
        
        guard clientId != "YOUR_STRAVA_CLIENT_ID" else {
            authError = "Strava API keys not configured. Add your client ID and secret to StravaService.swift."
            print("[StravaService] Strava API keys not configured")
            return
        }
        
        let scope = "read,activity:read_all"
        let authURLString = "\(authURL)?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=code&approval_prompt=auto&scope=\(scope)"
        
        guard let url = URL(string: authURLString) else {
            throw StravaError.invalidURL
        }
        
        // Launch ASWebAuthenticationSession
        let code = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "awakened"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: StravaError.authFailed(error.localizedDescription))
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: StravaError.noAuthCode)
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            session.presentationContextProvider = presentationContext
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
        
        // Exchange code for token
        try await exchangeCodeForToken(code: code)
        isConnected = true
    }
    
    /// Exchange authorization code for access + refresh tokens
    private func exchangeCodeForToken(code: String) async throws {
        guard let url = URL(string: tokenURL) else {
            throw StravaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StravaError.tokenExchangeFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
        
        // Store tokens in Keychain
        setKeychainValue(key: accessTokenKey, value: tokenResponse.accessToken)
        setKeychainValue(key: refreshTokenKey, value: tokenResponse.refreshToken)
        setKeychainValue(key: expiresAtKey, value: String(tokenResponse.expiresAt))
    }
    
    /// Refresh the access token if expired
    private func refreshTokenIfNeeded() async throws {
        guard let expiresAtString = getKeychainValue(key: expiresAtKey),
              let expiresAt = Int(expiresAtString) else { return }
        
        // Check if token is still valid (with 5 min buffer)
        guard Date().timeIntervalSince1970 >= Double(expiresAt - 300) else { return }
        
        guard let refreshToken = getKeychainValue(key: refreshTokenKey),
              let url = URL(string: tokenURL) else {
            throw StravaError.noRefreshToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StravaError.tokenRefreshFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
        
        setKeychainValue(key: accessTokenKey, value: tokenResponse.accessToken)
        setKeychainValue(key: refreshTokenKey, value: tokenResponse.refreshToken)
        setKeychainValue(key: expiresAtKey, value: String(tokenResponse.expiresAt))
    }
    
    // MARK: - API Methods (Stubbed)
    
    /// Fetch athlete activities from Strava
    /// - Parameters:
    ///   - page: Page number (1-indexed)
    ///   - perPage: Activities per page (max 200)
    /// - Returns: Array of StravaActivity
    func fetchActivities(page: Int = 1, perPage: Int = 30) async throws -> [StravaActivity] {
        // TODO: Enable when API keys are configured
        guard clientId != "YOUR_STRAVA_CLIENT_ID" else {
            print("[StravaService] Strava API not configured — returning empty activities")
            return []
        }
        
        try await refreshTokenIfNeeded()
        
        guard let accessToken = getKeychainValue(key: accessTokenKey) else {
            throw StravaError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseAPIURL)/athlete/activities?page=\(page)&per_page=\(perPage)") else {
            throw StravaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StravaError.apiFailed
        }
        
        return try JSONDecoder().decode([StravaActivity].self, from: data)
    }
    
    // MARK: - Disconnect
    
    /// Remove all Strava tokens and disconnect
    func disconnect() {
        deleteKeychainValue(key: accessTokenKey)
        deleteKeychainValue(key: refreshTokenKey)
        deleteKeychainValue(key: expiresAtKey)
        isConnected = false
        authError = nil
    }
    
    // MARK: - Keychain Helpers
    
    private func setKeychainValue(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getKeychainValue(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteKeychainValue(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Errors

enum StravaError: LocalizedError {
    case invalidURL
    case authFailed(String)
    case noAuthCode
    case tokenExchangeFailed
    case tokenRefreshFailed
    case noRefreshToken
    case notAuthenticated
    case apiFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Strava URL."
        case .authFailed(let msg): return "Strava auth failed: \(msg)"
        case .noAuthCode: return "No authorization code received from Strava."
        case .tokenExchangeFailed: return "Failed to exchange code for token."
        case .tokenRefreshFailed: return "Failed to refresh Strava token."
        case .noRefreshToken: return "No refresh token available."
        case .notAuthenticated: return "Not authenticated with Strava."
        case .apiFailed: return "Strava API request failed."
        }
    }
}
