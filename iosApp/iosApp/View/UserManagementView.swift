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
    
    var body: some View {
        VStack {
            Button("Logout") {
                oauth.logout()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
