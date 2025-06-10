//
//  UserManagementView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//

import SwiftUI

#Preview {
    UserManagementView()
}

struct UserManagementView: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationStack {
                Form {
                    Section("User Info") {
                        HStack {
                            Label("Email", systemImage: "envelope")
                            Spacer()
                            Text(UserInformation.shared.email ?? "")
                                .foregroundColor(.secondary)
                                .redacted(reason: UserInformation.shared.email?.isEmpty ?? false ? .placeholder : [])
                        }
                        Link("Manage account", destination: URL(string: "\(NetworkConstants.keycloakUrl)/realms/Users/account")!)
                        Button(role: .destructive) {
                            OAuthManager.shared.logout()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Logout")
                                Spacer()
                            }
                        }
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
                .background(BackgroundGradient())
                .scrollContentBackground(.hidden)
                .navigationTitle("User Management")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
