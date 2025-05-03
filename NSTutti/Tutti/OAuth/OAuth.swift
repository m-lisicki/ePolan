//
//  OAuth.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import AppAuth
import Shared

@MainActor @Observable
final class OAuthManager {
    static let shared = OAuthManager()
    private init() {}
    
    var authState: OIDAuthState?
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    let clientID = "ClassMatcher"
    let clientSecret = ""
    let redirectURI = URL(string: "com.baklava:/oauthredirect")!
    
    var dbCommunicationServices: DBCommunicationServices?
    var email: String?
    
    let configuration = OIDServiceConfiguration(
        authorizationEndpoint: URL(string: "http://localhost:8280/realms/Users/protocol/openid-connect/auth")!,
        tokenEndpoint: URL(string: "http://localhost:8280/realms/Users/protocol/openid-connect/token")!,
        issuer: URL(string: "http://localhost:8280/realms/Users")!,
        registrationEndpoint: nil,
        endSessionEndpoint: URL(string: "http://localhost:8280/realms/Users/protocol/openid-connect/logout")!
    )
    
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
        ) { [weak self] state, error in
                if let error = error {
                    log.error("Authorization error: \(error.localizedDescription)")
                } else if let state = state {
                    if let accessToken = state.lastTokenResponse?.accessToken {
                        self?.dbCommunicationServices = DBCommunicationServices(token: accessToken)
                    }
                    self?.authState = state
                    Task {
                        self?.email = try? await OAuthManager.shared.dbCommunicationServices?.getUserEmail()
                    }
                } else {
                    log.error("Unknown authorization error")
                }
            
        }
    }
    
    func resumeExternalUserAgentFlow(with url: URL) -> Bool {
        guard let flow = currentAuthorizationFlow, flow.resumeExternalUserAgentFlow(with: url) else {
            return false
        }
        currentAuthorizationFlow = nil
        return true
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
        ) { [weak self] response, error in
                if let error = error {
                    log.error("Logout error: \(error.localizedDescription)")
                } else {
                    log.info("Logged out successfully")
                    self?.authState = nil
                    self?.dbCommunicationServices = nil
                    self?.email = nil
                }
        }
    }
}
