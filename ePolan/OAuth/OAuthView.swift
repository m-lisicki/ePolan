//
//  OAuthView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//


import SwiftUI

#Preview {
    SignInView()
        .environment(OAuthManager.shared)
}

struct SignInView: View {
    @State private var showLogin = false
    @Environment(OAuthManager.self) private var oauth: OAuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text(oauth.authState?.lastTokenResponse?.accessToken ?? "Not logged in")
                .font(.headline)
            
            Button("Login") {
                oauth.authorize()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
