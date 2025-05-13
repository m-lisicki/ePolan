//
//  UserManagementView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import MessageUI

#Preview {
    @Previewable @State var accentColor: Color = .accent
    UserManagementView(accentColor: $accentColor)
        .environment(OAuthManager.shared)
}

struct UserManagementView: View {
    @Environment(OAuthManager.self) private var oauth
    @Environment(\.openURL) var openURL
    @Binding var accentColor: Color
    
    var body: some View {
        NavigationStack {
            Form {
                Section("User Info") {
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
                
                Section("Appearance") {
                    ColorPicker("Accent Color", selection: $accentColor)
                }
                
                Section("Contact & Support") {
                    Button {
                        let urlString = "mailto:m.lsck@icloud.com?subject=ePolan: bug report"
                        openURL(URL(string: urlString)!)
                    } label: {
                        HStack {
                            Label("Report a Problem", systemImage: "exclamationmark.triangle")
                        }
                    }
                    Button {
                        let urlString = "mailto:m.lsck@icloud.com?subject=ePolan: feedback"
                        openURL(URL(string: urlString)!)
                    } label: {
                        Label("Give Feedback", systemImage: "bubble.left.and.text.bubble.right")
                    }
                }
            }
            .navigationTitle("User Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
