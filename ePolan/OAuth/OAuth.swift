//
//  OAuth.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

@Observable
@MainActor
final class OAuthManager: NSObject {
    @MainActor static let shared = OAuthManager()
    
    private override init() {
        super.init()
        restoreAuthState()
    }
    
    // Keychain keys
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let idTokenKey = "idToken"
    private let expirationKey = "expiration"
    private let codeVerifierKey = "codeVerifier"
    private let emailKey = "userEmail"
    
    private var currentSession: ASWebAuthenticationSession?
    
    let clientID = "ClassMatcher"
    let clientSecret = ""
    let redirectURI = "com.baklava://oauthredirect"
    
    var email: String?
    var accessToken: String?
    private var refreshToken: String?
    private var idToken: String?
    private var expirationDate: Date?
    private var codeVerifier: String?
    
    private struct AuthEndpoints {
        private static let baseURLString = "\(NetworkConstants.keycloakUrl)/realms/Users/protocol/openid-connect"

        static var authURL: URL {
            URL(string: "\(baseURLString)/auth")!
        }

        static var tokenURL: URL {
            URL(string: "\(baseURLString)/token")!
        }

        static var logoutURL: URL {
            URL(string: "\(baseURLString)/logout")!
        }

        static var userInfoURL: URL {
            URL(string: "\(baseURLString)/userinfo")!
        }
    }
    
    // MARK: - Authorization Flow
    func authorize() {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        var components = URLComponents(url: AuthEndpoints.authURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "openid profile"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        
        guard let authURL = components.url else {
            log.error("Invalid authorization URL")
            return
        }
        
        self.codeVerifier = codeVerifier
        saveCodeVerifier(codeVerifier)
        
        currentSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "com.baklava"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                log.error("Authorization failed: \(error.localizedDescription)")
                return
            }
            
            guard let callbackURL = callbackURL,
                  let code = self.parseCode(from: callbackURL) else {
                log.error("Invalid callback URL")
                return
            }
            
            Task {
                await self.exchangeCodeForTokens(code: code)
            }
        }
        
        currentSession?.presentationContextProvider = self
        currentSession?.start()
    }
    
    // MARK: - Token Exchange
    private func exchangeCodeForTokens(code: String) async {
        guard let codeVerifier = codeVerifier else {
            log.error("Missing code verifier")
            return
        }
        
        var request = URLRequest(url: AuthEndpoints.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "authorization_code",
            "client_id": clientID,
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ].formURLEncoded()
        
        request.httpBody = body
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
            
            Task { @MainActor in
                self.accessToken = response.access_token
                self.refreshToken = response.refresh_token
                self.idToken = response.id_token
                self.expirationDate = Date().addingTimeInterval(TimeInterval(response.expires_in))
                
                self.saveAuthState()
                self.fetchUserEmail()
            }
        } catch {
            log.error("Token exchange failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Token Refresh
    private func refreshTokens() async throws {
        guard let refreshToken = refreshToken else {
            throw OAuthError.missingRefreshToken
        }
        
        var request = URLRequest(url: AuthEndpoints.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "refresh_token",
            "client_id": clientID,
            "refresh_token": refreshToken
        ].formURLEncoded()
        
        request.httpBody = body
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        
        Task { @MainActor in
            self.accessToken = response.access_token
            self.refreshToken = response.refresh_token ?? self.refreshToken
            self.expirationDate = Date().addingTimeInterval(TimeInterval(response.expires_in))
            self.saveAuthState()
        }
    }
    
    // MARK: - User Info
    private func fetchUserEmail() {
        Task {
            guard let accessToken = accessToken else { return }
            
            var request = URLRequest(url: AuthEndpoints.userInfoURL)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
                
                Task { @MainActor in
                    self.email = userInfo.email
                    try KeychainHelper.shared.save(string: userInfo.email, for: emailKey)
                }
            } catch {
                log.error("Failed to fetch user email: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Logout
    func logout() {
        guard let idToken = idToken else {
            clearAuthState()
            return
        }
        
        var components = URLComponents(url: AuthEndpoints.logoutURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "id_token_hint", value: idToken),
            URLQueryItem(name: "post_logout_redirect_uri", value: redirectURI)
        ]
        
        guard let logoutURL = components.url else {
            log.error("Invalid logout URL")
            return
        }
        
        currentSession = ASWebAuthenticationSession(
            url: logoutURL,
            callbackURLScheme: "com.baklava"
        ) { [weak self] _, error in
            if let error = error {
                log.error("Logout failed: \(error.localizedDescription)")
            } else {
                self?.clearAuthState()
            }
        }
        
        currentSession?.presentationContextProvider = self
        currentSession?.start()
    }
    
    // MARK: - Token Management
    func useFreshToken() async -> String {
        if let expiration = expirationDate, expiration < Date() {
            do {
                try await refreshTokens()
            } catch {
                log.error("Token refresh failed: \(error)")
                clearAuthState()
            }
        }
        return accessToken ?? ""
    }
    
    // MARK: - PKCE Generation
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
    }
    
    // MARK: - URL Parsing
    private func parseCode(from url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "code" })?.value
    }
    
    // MARK: - State Management
    private func saveAuthState() {
        do {
            if let accessToken = accessToken {
                try KeychainHelper.shared.save(string: accessToken, for: accessTokenKey)
            }
            if let refreshToken = refreshToken {
                try KeychainHelper.shared.save(string: refreshToken, for: refreshTokenKey)
            }
            if let idToken = idToken {
                try KeychainHelper.shared.save(string: idToken, for: idTokenKey)
            }
            if let expiration = expirationDate {
                try KeychainHelper.shared.save(date: expiration, for: expirationKey)
            }
        } catch {
            log.error("\(error)")
        }
        
    }
    
    private func restoreAuthState() {
        do {
            accessToken = try KeychainHelper.shared.loadString(key: accessTokenKey)
            refreshToken = try KeychainHelper.shared.loadString(key: refreshTokenKey)
            idToken = try KeychainHelper.shared.loadString(key: idTokenKey)
            expirationDate = try KeychainHelper.shared.loadDate(key: expirationKey)
            codeVerifier = try KeychainHelper.shared.loadString(key: codeVerifierKey)
            email = try KeychainHelper.shared.loadString(key: emailKey)
        } catch {
            log.error("\(error)")
        }
        
    }
    
    private func saveCodeVerifier(_ verifier: String) {
        do {
            try KeychainHelper.shared.save(string: verifier, for: codeVerifierKey)
        } catch {
            log.error("\(error)")
        }
    }
    
    private func clearAuthState() {
        do {
            try KeychainHelper.shared.delete(key: accessTokenKey)
            try KeychainHelper.shared.delete(key: refreshTokenKey)
            try KeychainHelper.shared.delete(key: idTokenKey)
            try KeychainHelper.shared.delete(key: expirationKey)
            try KeychainHelper.shared.delete(key: codeVerifierKey)
            try KeychainHelper.shared.delete(key: emailKey)
        } catch {
            log.error("\(error)")
        }
        
        accessToken = nil
        refreshToken = nil
        idToken = nil
        expirationDate = nil
        codeVerifier = nil
        email = nil
    }
    
    func isAuthorised(user: String) -> Bool {
        user == self.email ?? ""
    }
}

// MARK: - Extensions
extension OAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }!
    }
}


struct OAuthTokenResponse: Decodable {
    let access_token: String
    let refresh_token: String?
    let id_token: String?
    let expires_in: Int
    let token_type: String
}

struct UserInfo: Decodable {
    let email: String
}

enum OAuthError: Error {
    case missingRefreshToken
    case unauthorised
}

extension OAuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unauthorised:
            return "Session expired. Please re-authenticate."
        case .missingRefreshToken:
            return "No refresh token available. Please login again."
        }
    }
}

extension Dictionary where Key == String, Value == String {
    func formURLEncoded() -> Data {
        map { "\($0)=\($1.urlEncoded)" }
            .joined(separator: "&")
            .data(using: .utf8)!
    }
}

extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension View {
    @discardableResult
    func dbQuery<T: Sendable>(_ operation: (DBQuery) async throws -> T) async throws -> T {
        return try await operation(DBQuery())
    }
}

import Security

@MainActor
final class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let service: String
    private let accessibilityOption = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    
    private init(service: String = "com.baklava.oauth") {
        self.service = service
    }
    
    enum KeychainError: Error {
        case stringConversionFailed
        case unexpectedStatus(OSStatus)
        case itemNotFound
    }
    
    // MARK: - Generic Data Handling
    func save(data: Data, for key: String) throws {
        let attributesToSet: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibilityOption,
        ]
        
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        addQuery.merge(attributesToSet) { (_, new) in new }
        
        var status = SecItemAdd(addQuery as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let searchQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            status = SecItemUpdate(searchQuery as CFDictionary, attributesToSet as CFDictionary)
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func loadData(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        return data
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - Type-Specific Helpers
    func save(string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.stringConversionFailed
        }
        try save(data: data, for: key)
    }
    
    func loadString(key: String) throws -> String {
        let data = try loadData(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.stringConversionFailed
        }
        return string
    }
    
    func save(date: Date, for key: String) throws {
        let timeInterval = date.timeIntervalSince1970
        let data = String(timeInterval)
        try save(string: data, for: key)
    }
    
    func loadDate(key: String) throws -> Date {
        let data = try loadData(key: key)
        guard let timeIntervalString = String(data: data, encoding: .utf8)
                ,let timeInterval = TimeInterval(timeIntervalString) else {
            log.error("Failed to convert data to string")
            return Date()
        }
        return Date(timeIntervalSince1970: timeInterval)
    }
}
