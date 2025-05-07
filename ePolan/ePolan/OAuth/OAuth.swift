//
//  OAuth.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import AppAuth
@preconcurrency import Shared

let ipAddress = "192.168.254.134"

@Observable
@MainActor
final class OAuthManager {
    @MainActor static let shared = OAuthManager()
    private init() {}
    
    var authState: OIDAuthState?
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    let clientID = "ClassMatcher"
    let clientSecret = ""
    let redirectURI = URL(string: "com.baklava:/oauthredirect")!
    
    var email: String?
    
    func useCommunicationServices() async -> DBCommunicationServices {
        let freshToken = await returnFreshToken()
        return DBCommunicationServices(token: freshToken)
    }
        
    let configuration = OIDServiceConfiguration(
        authorizationEndpoint: URL(string: "http://\(ipAddress):8280/realms/Users/protocol/openid-connect/auth")!,
        tokenEndpoint: URL(string: "http://\(ipAddress):8280/realms/Users/protocol/openid-connect/token")!,
        issuer: URL(string: "http://\(ipAddress):8280/realms/Users")!,
        registrationEndpoint: nil,
        endSessionEndpoint: URL(string: "http://\(ipAddress):8280/realms/Users/protocol/openid-connect/logout")!
    )
    
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
                        let dbService = await OAuthManager.shared.useCommunicationServices()
                        self?.email = try await dbService.getUserEmail()
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
    func dbQuery<T: Sendable>(_ operation: (DBCommunicationServices) async throws -> T) async throws -> T {
        let dbService = await OAuthManager.shared.useCommunicationServices()
        return try await operation(dbService)
    }
}
