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
                        NavigationLink(destination: LessonView(course: course)) {
                            Text(course.name)
                                .font(.headline)
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
                let setCourses = try? await OAuthManager.shared.dbCommunicationServices?.getAllCourses()
                if let setCourses = setCourses {
                    courses = Array(setCourses).sorted { $0.name < $1.name }
                }
            }
        }
    }
}

struct ModifyCourseUsers: View {
    let course: CourseDto
    
    @State var users: Array<String> = []
    @State var showingAlert = false
    @State var email: String = ""
    
    @State var currentUser: String = ""

    
    var body: some View {
        VStack {
                List(users, id: \.self) { user in
                    Text(user)
                        .background(user == currentUser ? Color.yellow : Color.clear)
                        .swipeActions {
                            if (user != currentUser) {
                                Button("Delete") {
                                    removeUser(email: user)
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
                        addUser(email: EmailHelper.trimCharacters(email))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!EmailHelper.isEmailValid(email) || users.contains(EmailHelper.trimCharacters(email)))
                }
                .padding()
        }
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

// TODO: - Rows names should display dates - not courseName
// everything with lessonAndTask.lesson.courseName -> Replace
struct LessonView: View {
    let course: CourseDto
    @State var lessons: [LessonDto]?
    
    var body: some View {
        VStack {
            if let lessons = lessons {
                List {
                    ForEach(lessons, id: \.id) { lesson in
                        Section(header: Text(lesson.statusText)) {
                            lessonView(for: lesson)
                        }
                    }
                }
                .toolbar {
                    NavigationLink(destination: ModifyCourseUsers(course: course)) {
                        Image(systemName: "person.fill")
                    }
                }
            } else {
                Image(systemName: "person.crop.circle")
                Text("No lessons")
            }
        }
        .onAppear {
            Task {
                lessons = try? await OAuthManager.shared.dbCommunicationServices?.getAllLessons(courseId: course.id)
                if let lessons = lessons {
                    self.lessons = lessons
                }
            }
        }
    }
    
    @ViewBuilder
    private func lessonView(for lesson: LessonDto) -> some View {
        if !lesson.exercises.isEmpty {
            if lesson.lessonStatus == .past {
                NavigationLink(destination: TasksAssignedView(title: "TODO", lesson: lesson)) {
                    Text(lesson.courseName)
                        .font(.headline)
                }
            } else if lesson.lessonStatus == .near {
                NavigationLink(destination: TasksDetailView(title: "TODO", lesson: lesson)) {
                    VStack(alignment: .leading) {
                        Text(lesson.courseName)
                            .font(.headline)
                    }
                }
            } else {
                Text(lesson.courseName)
                    .font(.headline)
            }
        } else {
            Text(lesson.courseName)
                .font(.headline)
        }
    }
}

extension LessonDto {
    var statusText: String {
        switch lessonStatus {
        case .past: return "Past"
        case .near: return "Near"
        case .future: return "Future"
        default: return "Unknown"
        }
    }
}
