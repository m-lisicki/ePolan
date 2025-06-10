//
//  OAuth.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//

import AuthenticationServices
import CryptoKit
import SwiftUI

@Observable
@MainActor
final class UserInformation {
    static let shared = UserInformation()
    private init() {}
    
    var email: String?
    
    var isLoggedIn: Bool = false

    func isAuthorised(user: String) -> Bool {
#if !DEBUG
        user == email ?? ""
#else
        true
#endif
    }
}

@MainActor
final class OAuthManager: NSObject {
    static let shared = OAuthManager()

    override private init() {
        super.init()
        restoreAuthState()
    }

    // Keychain keys
    private static let accessTokenKey = "accessToken"
    private static let refreshTokenKey = "refreshToken"
    private static let idTokenKey = "idToken"
    private static let expirationKey = "expiration"
    private static let codeVerifierKey = "codeVerifier"
    private static let emailKey = "userEmail"

    private var currentSession: ASWebAuthenticationSession?

    private static let clientID = "ClassMatcher"
    private static let clientSecret = ""
    private static let redirectURI = "com.baklava://oauthredirect"

    private var accessToken: String? {
        didSet {
            if accessToken != nil {
                UserInformation.shared.isLoggedIn = true
            } else {
                UserInformation.shared.isLoggedIn = false
            }
        }
    }

    private var refreshToken: String?
    private var idToken: String?
    private var expirationDate: Date?
    private var codeVerifier: String?

    private enum AuthEndpoints {
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

    func authorize() async {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        var components = URLComponents(url: AuthEndpoints.authURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: OAuthManager.clientID),
            URLQueryItem(name: "redirect_uri", value: OAuthManager.redirectURI),
            URLQueryItem(name: "scope", value: "openid profile"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]

        guard let authURL = components.url else {
            log.error("Invalid authorization URL")
            return
        }

        self.codeVerifier = codeVerifier
        saveCodeVerifier(codeVerifier)

        currentSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "com.baklava",
        ) { [weak self] callbackURL, error in
            guard let self else { return }

            if let error {
                log.error("Authorization failed: \(error.localizedDescription)")
                return
            }

            guard let callbackURL,
                  let code = parseCode(from: callbackURL)
            else {
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
        guard let codeVerifier else {
            log.error("Missing code verifier")
            return
        }

        var request = URLRequest(url: AuthEndpoints.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "authorization_code",
            "client_id": OAuthManager.clientID,
            "code": code,
            "redirect_uri": OAuthManager.redirectURI,
            "code_verifier": codeVerifier,
        ].formURLEncoded()

        request.httpBody = body

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)

            accessToken = response.access_token
            refreshToken = response.refresh_token
            idToken = response.id_token
            expirationDate = Date().addingTimeInterval(TimeInterval(response.expires_in))
            saveAuthState()
            await fetchUserEmail()
        } catch {
            log.error("Token exchange failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Token Refresh

    private func refreshTokens() async throws {
        guard let refreshToken else {
            throw OAuthError.missingRefreshToken
        }

        var request = URLRequest(url: AuthEndpoints.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "refresh_token",
            "client_id": OAuthManager.clientID,
            "refresh_token": refreshToken,
        ].formURLEncoded()

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.somethingJustWentWrong
        }

        if httpResponse.statusCode == 200 {
            let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
            accessToken = response.access_token
            self.refreshToken = response.refresh_token ?? self.refreshToken
            expirationDate = Date().addingTimeInterval(TimeInterval(response.expires_in))
            saveAuthState()
        } else {
            let keycloakError = try? JSONDecoder().decode(KeycloakError.self, from: data)
            if let keycloakError {
                throw OAuthError.keycloakError(error: keycloakError.error, description: keycloakError.error_description)
            } else {
                throw OAuthError.somethingJustWentWrong
            }
        }
    }

    // MARK: - User Info

    private func fetchUserEmail() async {
        guard let accessToken else { return }

        var request = URLRequest(url: AuthEndpoints.userInfoURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
            Task(priority: .background) { @MainActor in
                UserInformation.shared.email = userInfo.email
            }
            try KeychainHelper.shared.save(string: userInfo.email, for: OAuthManager.emailKey)
        } catch {
            log.error("Failed to fetch user email: \(error.localizedDescription)")
        }
    }

    // MARK: - Logout

    func logout() {
        guard let idToken else {
            clearAuthState()
            return
        }

        var components = URLComponents(url: AuthEndpoints.logoutURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "id_token_hint", value: idToken),
            URLQueryItem(name: "post_logout_redirect_uri", value: OAuthManager.redirectURI),
        ]

        guard let logoutURL = components.url else {
            log.error("Invalid logout URL")
            return
        }

        currentSession = ASWebAuthenticationSession(
            url: logoutURL,
            callbackURLScheme: "com.baklava",
        ) { [weak self] _, error in
            if let error {
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
            } catch let error as OAuthError {
                switch error {
                case let .keycloakError(errorCode, _):
                    if errorCode == "invalid_grant" {
                        log.error("Token refresh failed: \(errorCode)")
                        clearAuthState()
                    } else {
                        log.error("Unhandled Authorisation Error: \(error.localizedDescription)")
                    }
                case .missingRefreshToken:
                    log.error("Token refresh failed: \(error.localizedDescription)")
                    clearAuthState()
                case .somethingJustWentWrong:
                    log.error("Something just went wrong: \(error.localizedDescription)")
                }
            } catch {
                log.error("Unhandled Authorisation Error: \(error.localizedDescription)")
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
            if let accessToken {
                try KeychainHelper.shared.save(string: accessToken, for: OAuthManager.accessTokenKey)
            }
            if let refreshToken {
                try KeychainHelper.shared.save(string: refreshToken, for: OAuthManager.refreshTokenKey)
            }
            if let idToken {
                try KeychainHelper.shared.save(string: idToken, for: OAuthManager.idTokenKey)
            }
            if let expiration = expirationDate {
                try KeychainHelper.shared.save(date: expiration, for: OAuthManager.expirationKey)
            }
        } catch {
            log.error("\(error)")
        }
    }

    private func restoreAuthState() {
        do {
            accessToken = try KeychainHelper.shared.loadString(key: OAuthManager.accessTokenKey)
            refreshToken = try KeychainHelper.shared.loadString(key: OAuthManager.refreshTokenKey)
            idToken = try KeychainHelper.shared.loadString(key: OAuthManager.idTokenKey)
            expirationDate = try KeychainHelper.shared.loadDate(key: OAuthManager.expirationKey)
            codeVerifier = try KeychainHelper.shared.loadString(key: OAuthManager.codeVerifierKey)
            UserInformation.shared.email = try KeychainHelper.shared.loadString(key: OAuthManager.emailKey)
        } catch {
            log.error("\(error)")
        }
    }

    private func saveCodeVerifier(_ verifier: String) {
        do {
            try KeychainHelper.shared.save(string: verifier, for: OAuthManager.codeVerifierKey)
        } catch {
            log.error("\(error)")
        }
    }

    private func clearAuthState() {
        do {
            try KeychainHelper.shared.delete(key: OAuthManager.accessTokenKey)
            try KeychainHelper.shared.delete(key: OAuthManager.refreshTokenKey)
            try KeychainHelper.shared.delete(key: OAuthManager.idTokenKey)
            try KeychainHelper.shared.delete(key: OAuthManager.expirationKey)
            try KeychainHelper.shared.delete(key: OAuthManager.codeVerifierKey)
            try KeychainHelper.shared.delete(key: OAuthManager.emailKey)
        } catch {
            log.error("\(error)")
        }

        accessToken = nil
        refreshToken = nil
        idToken = nil
        expirationDate = nil
        codeVerifier = nil
        UserInformation.shared.email = nil
    }
}

// MARK: - Extensions

extension OAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
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

struct KeycloakError: Decodable {
    let error: String
    let error_description: String?
}

struct UserInfo: Decodable {
    let email: String
}

enum OAuthError: Error {
    case missingRefreshToken
    case keycloakError(error: String, description: String?)
    case somethingJustWentWrong
}

extension [String: String] {
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

import Security

final class KeychainHelper: Sendable {
    static let shared = KeychainHelper()

    private let service: String
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
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        addQuery.merge(attributesToSet) { _, new in new }

        var status = SecItemAdd(addQuery as CFDictionary, nil)

        if status == errSecDuplicateItem {
            let searchQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
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
            kSecMatchLimit as String: kSecMatchLimitOne,
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
            kSecAttrAccount as String: key,
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
        guard let timeIntervalString = String(data: data, encoding: .utf8),
              let timeInterval = TimeInterval(timeIntervalString)
        else {
            log.error("Failed to convert data to string")
            return Date()
        }
        return Date(timeIntervalSince1970: timeInterval)
    }
}
