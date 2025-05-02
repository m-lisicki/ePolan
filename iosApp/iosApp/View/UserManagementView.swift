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
                        Text(OAuthManager.shared.email ?? "?")
                            .foregroundColor(.secondary)
                    }
                    Button(role: .destructive) {
                            oauth.logout()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Logout")
                                Spacer()
                            }
                        }
                }
                
                Section(header: Text("Appearance")) {
                    ColorPicker("Accent Color", selection: $accentColor)
                }

                
            }
            .navigationTitle("User Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

