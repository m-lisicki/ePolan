//
//  UserManagementView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

struct UserManagementView: View {
    @Environment(OAuthManager.self) private var oauth
    @Binding var accentColor: Color
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("User Info")) {
                    HStack {
                        Label("Email", systemImage: "envelope")
                        Spacer()
                        Text(OAuthManager.shared.email ?? "")
                            .foregroundColor(.secondary)
                            .redacted(reason: OAuthManager.shared.email?.isEmpty ?? false ? .placeholder : [])
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

