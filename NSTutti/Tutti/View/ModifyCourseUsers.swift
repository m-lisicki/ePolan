//
//  ModifyCourseUsers.swift
//  iosApp
//
//  Created by Michał Lisicki on 02/05/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

struct ModifyCourseUsers: View {
    let course: CourseDto
    
    @State var users: Array<String> = []
    @State var showingAlert = false
    @State var email: String = ""
    
    var currentUser: String {
        OAuthManager.shared.email ?? ""
    }
    
    
    var body: some View {
        VStack {
            List(users, id: \.self) { user in
                Text(user)
                    .bold(user == currentUser)
                    .swipeActions {
                        if (user != currentUser) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await removeUser(email: user)
                                }
                            }
                            .tint(.red)
                        }
                    }
            }
            .listStyle(.plain)
            .padding()
            HStack {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    Task {
                        await addUser(email: EmailHelper.trimCharacters(email))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!EmailHelper.isEmailValid(email) || users.contains(EmailHelper.trimCharacters(email)))
            }
            .padding()
        }
        .navigationTitle("Modify course users")
        .navigationBarTitleDisplayMode(.inline)
        .task {
                let userSet = try? await OAuthManager.shared.dbCommunicationServices?.getAllStudents(courseId: course.id)
                if let userSet = userSet {
                    users = Array(userSet).sorted { $0 < $1 }
                }
            
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text("Something went wrong. Try again later."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func addUser(email: String) async {
            let status = try? await OAuthManager.shared.dbCommunicationServices?.addStudent(courseId: course.id, email: email)
            if status != 200 {
                showingAlert = true
                return
            }
            self.users.append(email)
            self.email = ""
        
    }
    
    func removeUser(email: String) async {
            let status = try? await OAuthManager.shared.dbCommunicationServices?.removeStudent(courseId: course.id, email: email)
            if status != 200 {
                showingAlert = true
                return
            }
            self.users.removeAll { $0 == email }
        
    }
}
