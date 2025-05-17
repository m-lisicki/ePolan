//
//  ContentView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//


import SwiftUI

#Preview {
    BottomBarView()
        .environment(OAuthManager.shared)
        .environment(NetworkMonitor())
        .environment(RefreshController())
}

struct ContentView: View {
    @Environment(OAuthManager.self) var oauth: OAuthManager
    @State private var alertMessage: String?

    
    var body: some View {
        VStack {
#if !targetEnvironment(simulator)
            if !oauth.isLoggedIn {
                SignInView()
            } else {
                BottomBarView()
            }
#else
            BottomBarView()
#endif
        }
    }
}

struct BottomBarView: View {
    @State var accentColor: Color = .accent
    
    var body: some View {
        TabView {
            CourseView()
                .tabItem {
                    Label("Courses", systemImage: "book")
                }
            UserManagementView(accentColor: $accentColor)
                .tabItem {
                    Label("User", systemImage: "person.crop.circle")
                }
        }
        .tint(accentColor)
    }
}
