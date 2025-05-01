//
//  UserManagementView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

struct UserManagementView: View {
    @EnvironmentObject private var oauth: OAuthManager
    @Binding var accentColor: Color
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("User Info")) {
                    HStack {
                        Label("Email", systemImage: "envelope")
                        Spacer()
                        Text(OAuthManager.shared.email ?? "User")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Appearance")) {
                    ColorPicker("Accent Color", selection: $accentColor)
                }

                
            }
            Button("Logout", role: .destructive) {
                oauth.logout()
            }
            .buttonStyle(.borderedProminent)
            .navigationTitle("User Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

