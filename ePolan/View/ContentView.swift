//
//  ContentView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//

import SwiftUI

 #Preview {
    BottomBarView()
        .environment(NetworkMonitor())
 }

struct ContentView: View {
    var body: some View {
        VStack {
            #if !DEBUG
                if UserInformation.shared.isLoggedIn == false {
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
    let networkMonitor = NetworkMonitor()

    var body: some View {
        TabView {
            CourseView()
                .tabItem {
                    Label("Courses", systemImage: "book")
                }
                .environment(networkMonitor)
            UserManagementView()
                .tabItem {
                    Label("User", systemImage: "person.crop.circle")
                }
        }
    }
}
