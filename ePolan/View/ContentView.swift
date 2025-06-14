//
//  ContentView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//

import SwiftUI

 #Preview {
    BottomBarView()
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
    var body: some View {
                NavigationSplitView {
                    CourseView()
                } content: {
                    ContentUnavailableView("No courses selected", systemImage: "book")
                } detail: {
                    ContentUnavailableView("No lesson selected", systemImage: "person.crop.circle")
                }
                .environment(NetworkMonitor())
    }
}
