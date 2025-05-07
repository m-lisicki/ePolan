//
//  ContentView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//


import SwiftUI

struct ContentView: View {
    @Environment(OAuthManager.self) var oauth: OAuthManager
    
    var body: some View {
        VStack {
            if OAuthManager.shared.authState == nil {
                SignInView()
            } else {
                BottomBarView()
            }
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
