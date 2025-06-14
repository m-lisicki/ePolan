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
                    #if !os(macOS)
                    reportProblemButton()
                    giveFeedbackButton()
                    #else
                    HStack {
                        reportProblemButton()
                        giveFeedbackButton()
                    }
                    #endif
                }
            }
            .navigationTitle("User Management")
#if !os(macOS)
            .background(BackgroundGradient())
            .navigationBarTitleDisplayMode(.inline)
#else
            .formStyle(.grouped)
#endif
        }
    }

    @ViewBuilder
    func createMailButton(subject: String, label: String, systemImage: String) -> some View {
        Button {
            let urlString = "mailto:m.lsck@icloud.com?subject=\(subject)"
            if let url = URL(string: urlString) {
                openURL(url)
            }
        } label: {
            Label(label, systemImage: systemImage)
        }
    }

    @ViewBuilder
    func reportProblemButton() -> some View {
        createMailButton(subject: "ePolan: bug report", label: "Report a Problem", systemImage: "exclamationmark.triangle")
    }

    @ViewBuilder
    func giveFeedbackButton() -> some View {
        createMailButton(subject: "ePolan: feedback", label: "Give Feedback", systemImage: "bubble.left.and.text.bubble.right")
    }

}
