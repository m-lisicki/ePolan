//
//  CourseView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

#Preview {
    CourseView()
        .environment(NetworkMonitor())
        .environment(RefreshController())
}

struct CourseView: View {
    @State var courses = Array<CourseDto>()
    
    @State var showAddCode = false
    @State var showCreate = false
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    List($courses, id: \.id) { $course in
//                        if !course.isArchived {
                            NavigationLink(destination: LessonsView(course: course)) {
                                Text(course.name)
                                    .font(.headline)
                            }
                            .swipeActions {
//                                Button("Archive") {
//                                    Task {
//                                        try await DBQuery.archiveCourse(courseId: course.id)
//                                        await fetchData()
//                                    }
//                                }
                            }
//                        }
                    }
                    .refreshable {
                        await fetchData(forceRefresh: true)
                    }
                    .overlay {
                        if courses.isEmpty {
                            ContentUnavailableView("No courses", systemImage: "compass.drawing")
                        }
                    }
                }
            }
            .navigationTitle("Courses")
            .overlay(alignment: .bottom) {
                if showAddCode {
                    JoinCourseView(showAddCode: $showAddCode)
                        .transition(.slide)
                        .background(.thinMaterial)
                }
            }
            .toolbar {
//                let archivedCourses = courses.filter(\.isArchived)
//                if !archivedCourses.isEmpty {
//                    ToolbarItem {
//                        NavigationLink(destination: ArchivedCoursesView(archivedCourses: archivedCourses)) {
//                            Image(systemName: "archivebox")
//                        }
//                    }
//                }
                ToolbarItem {
                    Button(action: {
                        withAnimation {
                            showAddCode.toggle()
                        }
                    }) {
                        Image(systemName: "person.2.badge.plus")
                    }
                    .accessibilityLabel("Join course")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { withAnimation { showCreate = true } }) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                    }
                    .accessibilityLabel("Add new course")
                }
            }
            .task {
#if !targetEnvironment(simulator)
                await fetchData()
#else
                courses = CourseDto.getMockData()
#endif
            }
            .onChange(of: showAddCode) { _, newValue in
                if !newValue {
                    Task {
                        await fetchData()
                    }
                }
            }
            .onChange(of: networkMonitor.isConnected) {
                Task {
                    await fetchData()
                }
            }
            .sheet(isPresented: $showCreate) {
                NavigationStack {
                    CreateCourseView(courses: $courses)
                        .presentationSizing(.form)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showCreate = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func fetchData(forceRefresh: Bool = false) async {
        let setCourses = try? await DBQuery.getAllCourses(forceRefresh: forceRefresh)
        
        
        if let setCourses = setCourses {
            courses = Array(setCourses).sorted { $0.name < $1.name }
        }
    }
}

struct JoinCourseView: View {
    @State var invitationCode: String = ""
    @Binding var showAddCode: Bool
    
    var body: some View {
        HStack {
            TextField("Enter invitation code", text: $invitationCode)
            Button("Join") {
                Task {
                    try await DBQuery.joinCourse(invitationCode: invitationCode)
                }
                withAnimation {
                    showAddCode = false
                }
            }
        }
        .padding()
    }
}

struct ArchivedCoursesView: View {
    let archivedCourses: [CourseDto]
    
    var body: some View {
        List(archivedCourses, id: \.id) { course in
            Text(course.name)
        }
    }
}
