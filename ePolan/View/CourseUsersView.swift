//
//  ModifyCourseUsers.swift
//  ePolan
//
//  Created by Michał Lisicki on 02/05/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

#Preview {
    CourseUsers(course: CourseDto.getMockData().first!)
        .environment(NetworkMonitor())
}

struct CourseUsers: View, FallbackView {
    typealias T = String
    
    let course: CourseDto
    
    @State var data: Set<String>? {
        didSet {
            users = data?.sorted(by: <) ?? []
        }
    }
    
    @State var users: Array<String> = []
    @State var email: String = ""
    
    var currentUser: String {
        OAuthManager.shared.email ?? ""
    }
    
        
    @State var showApiError: Bool = false
    @State var apiError: ApiError? {
        didSet {
            if networkMonitor.isConnected {
                showApiError = true
            }
        }
    }
    
    @Environment(NetworkMonitor.self) var networkMonitor
    
    var body: some View {
        VStack {
            List(users, id: \.self) { user in
                Text(user)
                    .bold(user == currentUser)
                    .swipeActions {
                        if (user != currentUser) && OAuthManager.shared.isAuthorised(user: course.creator) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await removeUser(email: user)
                                }
                            }
                            .tint(.red)
                        }
                    }
            }
            .errorAlert(isPresented: $showApiError, error: apiError)
            .fallbackView(viewState: viewState, fetchData: fetchData)
            .listStyle(.plain)
            .padding()
            if OAuthManager.shared.isAuthorised(user: course.creator) {
                HStack {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
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
            HStack {
                VStack(alignment: .leading) {
                    Text("Invitation code:")
                        .font(.subheadline)
                    Text(course.courseCode)
                        .font(.caption)
                        .draggable(course.courseCode)
                }
                Spacer()
                Button("Copy") {
                    UIPasteboard.general.string = course.courseCode
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onChange(of: networkMonitor.isConnected) {
            Task {
                await fetchData()
            }
        }
        .navigationTitle("Course users")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchData()
        }
    }
    
    func fetchData(forceRefresh: Bool = false) async {
#if !targetEnvironment(simulator)
        do {
            data = try await DBQuery.getAllStudents(courseId: course.id)
        } catch {
            apiError = error.mapToApiError()
        }
#else
        data = Set(["Dr. Strangelove", "David Bowie", "Witkacy"])
#endif
    }
    
    func addUser(email: String) async {
        do {
            try await DBQuery.addStudent(courseId: course.id, email: email)
            data?.insert(email)
            self.email = ""
        } catch {
            apiError = error.mapToApiError()
        }
    }
    
    func removeUser(email: String) async {
        do {
            try await DBQuery.removeStudent(courseId: course.id, email: email)
            self.users.removeAll { $0 == email }
        } catch {
            apiError = error.mapToApiError()
        }
    }
}
