//
//  OAuthView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//


import SwiftUI

#Preview {
    NavigationStack {
        SignInView()
            .environment(OAuthManager.shared)
    }
}

struct SignInView: View {
    @State private var showLogin = false
    @Environment(OAuthManager.self) private var oauth: OAuthManager
    
    var body: some View {
        ZStack {
            BackgroundGradient()
            VStack(spacing: 75) {
                Text("ePolan")
                    .fontWeight(.bold)
                    .font(.largeTitle)
                    .italic()
                
                VStack(spacing: 20) {
                    Text("Not logged in")
                        .fontWeight(.medium)
                        .font(.headline)
                        .padding(7)
                        .background(.ultraThinMaterial)
                        .cornerRadius(5)
                    
                    Button("Login") {
                        oauth.authorize()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}

struct BackgroundGradient: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reducedMotion
    @State var isAnimating = true
    
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.8 : 0.3, isAnimating ? 0.2 : 0.6], [1.0, isAnimating ? 0.5 : 0.3],
                [0.0, 1.0], [isAnimating ? 0.3 : 0.6, 1.0], [1.0, 1.0]
            ],
            colors: colorScheme == .light ?
            [   .white, .green, .white,
                .blue, .teal, .mint,
                .pink, .purple, .white
            ]
            :
                [.black, .indigo, .red,
                 .green, .black, .green,
                 .black, .purple, .pink],
            smoothsColors: true
        )
        .onAppear {
            if !reducedMotion {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    isAnimating.toggle()
                }
            }
        }
        .ignoresSafeArea()
    }
}
