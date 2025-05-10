//
//  OAuth.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import AppAuth

@Observable
@MainActor
final class OAuthManager: NSObject, OIDAuthStateChangeDelegate {
    @MainActor static let shared = OAuthManager()
    
    private override init() {
        super.init()
        restoreAuthState()
    }
    
    private let keychainKey = "OIDAuthState"
    
    var authState: OIDAuthState? {
        didSet {
            authState?.stateChangeDelegate = self
            Task {
                await saveAuthState()
            }
        }
    }
    
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    let clientID = "ClassMatcher"
    let clientSecret = ""
    let redirectURI = URL(string: "com.baklava:/oauthredirect")!
    
    var email: String?
    
    let configuration = OIDServiceConfiguration(
        authorizationEndpoint: URL(string: "http://\(NetworkConstants.ip):8280/realms/Users/protocol/openid-connect/auth")!,
        tokenEndpoint: URL(string: "http://\(NetworkConstants.ip):8280/realms/Users/protocol/openid-connect/token")!,
        issuer: URL(string: "http://\(NetworkConstants.ip):8280/realms/Users")!,
        registrationEndpoint: nil,
        endSessionEndpoint: URL(string: "http://\(NetworkConstants.ip):8280/realms/Users/protocol/openid-connect/logout")!
    )
    
    // MARK: – Persistence
    
    private func saveAuthState() async {
        guard let state = authState else {
            try? KeychainHelper.shared.delete(key: keychainKey)
            return
        }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: state, requiringSecureCoding: true)
            try KeychainHelper.shared.save(data, for: keychainKey)
        } catch {
            log.error("Keychain save failed: \(error)")
        }
    }
    
    private func restoreAuthState() {
        guard let data = KeychainHelper.shared.load(key: keychainKey), let state = try? NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data)
        else { return }
        
        self.authState = state
        
        Task {
            self.email = try await DBQuery.getUserEmail()
        }
    }
    
    // MARK: - OIDAuthStateChangeDelegate Methods
    
    nonisolated func didChange(_ state: OIDAuthState) {
        log.info("OIDAuthState did change. Persisting updated state to Keychain...")
        Task {
            await saveAuthState()
        }
    }
    
    // MARK: - Ensure Fresh Tokens
    func returnFreshToken() async -> String {
        await withCheckedContinuation { continuation in
            authState?.performAction { accessToken, idToken, error in
                if let token = accessToken {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
    // MARK: — START FLOW
    func authorize() {
        guard authState == nil else { return }
        
        let request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientID,
                                              clientSecret: clientSecret,
                                              scopes: [OIDScopeOpenID, OIDScopeProfile],
                                              redirectURL: redirectURI,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)
        
        log.info("🔑 Initiating authorization with scopes: \(request.scope ?? "none")")
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            log.error("Unable to retrieve the root view controller.")
            return
        }
        
        let externalAgent = OIDExternalUserAgentIOS(presenting: rootVC)
        
        // Perform the auth request
        self.currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: request,
            externalUserAgent: externalAgent!
        ) { @MainActor [weak self] state, error in
            if let error = error {
                log.error("Authorization error: \(error.localizedDescription)")
            } else if let state = state {
                self?.authState = state
                Task {
                    self?.email = try await DBQuery.getUserEmail()
                }
            } else {
                log.error("Unknown authorization error")
            }
            
        }
    }
    
    func logout() {
        guard let idToken = authState?.lastTokenResponse?.idToken else {
            log.warning("No ID token found for logout.")
            self.authState = nil
            return
        }
        
        let endSessionRequest = OIDEndSessionRequest(
            configuration: configuration,
            idTokenHint: idToken,
            postLogoutRedirectURL: redirectURI,
            additionalParameters: nil
        )
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            log.error("Unable to retrieve the root view controller.")
            return
        }
        
        let externalAgent = OIDExternalUserAgentIOS(presenting: rootVC)
        
        currentAuthorizationFlow = OIDAuthorizationService.present(
            endSessionRequest,
            externalUserAgent: externalAgent!
        ) { @MainActor [weak self] response, error in
            if let error = error {
                log.error("Logout error: \(error.localizedDescription)")
            } else {
                log.info("Logged out successfully")
                self?.authState = nil
                self?.email = nil
            }
        }
    }
    
    func isAuthorised(user: String) -> Bool {
        user == self.email ?? ""
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
    
    func save(_ data: Data, for key: String) throws {
        let attributesToSet: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibilityOption
        ]
        
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        addQuery.merge(attributesToSet) { (_, new) in new }
        
        var status = SecItemAdd(addQuery as CFDictionary, nil)
        
        // If duplicate found - update
        if status == errSecDuplicateItem {
            let searchQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            status = SecItemUpdate(searchQuery as CFDictionary, attributesToSet as CFDictionary)
        }
        
        guard status == errSecSuccess else {
            // TODO: - THROW
            return
        }
    }
    
    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        guard let data = item as? Data else {
            return nil
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
            // TODO: - THROW
            return
        }
    }
}
