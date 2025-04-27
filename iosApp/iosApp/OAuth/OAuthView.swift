//
//  OAuthView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//


import SwiftUI
import UIKit

struct SignInView: View {
    @State private var showLogin = false
    @EnvironmentObject private var oauth: OAuthManager
    
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
