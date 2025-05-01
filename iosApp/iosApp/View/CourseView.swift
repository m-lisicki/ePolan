//
//  PointsView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

#Preview {
    CourseView()
}

struct CourseView: View {
    @State var courses: Array<CourseDto>?
    
    var body: some View {
        NavigationStack {
            VStack {
                if let courses = courses {
                    List(courses, id: \.id) { course in
                        NavigationLink(destination: LessonsView(course: course, lessons: course.lessons)) {
                            Text(course.name)
                                .font(.headline)
                        }
                    }
                    .refreshable {
                        Task {
                            await fetchData()
                        }
                    }
                    .navigationTitle("Courses")
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .imageScale(.large)
                        Text("No courses found!")
                    }
                }
            }
            .toolbar {
                NavigationLink(destination: CreateCourseView(courses: $courses)) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            Task {
                await fetchData()
            }
        }
    }
    
    private func fetchData() async {
        let setCourses = try? await OAuthManager.shared.dbCommunicationServices?.getAllCourses()
        if let setCourses = setCourses {
            courses = Array(setCourses).sorted { $0.name < $1.name }
        }
    }
}

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
                                removeUser(email: user)
                            }
                        }
                    }
            }
            .listStyle(.plain)
            .padding()
            HStack {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    addUser(email: EmailHelper.trimCharacters(email))
                }
                .buttonStyle(.borderedProminent)
                .disabled(!EmailHelper.isEmailValid(email) || users.contains(EmailHelper.trimCharacters(email)))
            }
            .padding()
        }
        .navigationTitle("Modify course users")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                let userSet = try await OAuthManager.shared.dbCommunicationServices?.getAllStudents(courseId: course.id)
                if let userSet = userSet {
                    users = Array(userSet).sorted { $0 < $1 }
                }
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
    
    func addUser(email: String) {
        Task {
            let status = try await OAuthManager.shared.dbCommunicationServices?.addStudent(courseId: course.id, email: email)
            if status != 200 {
                showingAlert = true
                return
            }
            self.users.append(email)
            self.email = ""
        }
    }
    
    func removeUser(email: String) {
        Task {
            let status = try await OAuthManager.shared.dbCommunicationServices?.removeStudent(courseId: course.id, email: email)
            if status != 200 {
                showingAlert = true
                return
            }
            self.users.removeAll { $0 == email }
        }
    }
}
