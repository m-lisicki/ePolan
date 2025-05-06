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
    @State var showAddCode = false
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        NavigationStack {
            VStack {
                if let courses = courses {
                    ZStack {
                        List(courses, id: \.id) { course in
                            if !course.isArchived {
                                NavigationLink(destination: LessonsView(course: course)) {
                                    Text(course.name)
                                        .font(.headline)
                                }
                                .swipeActions {
                                    Button("Archive") {
                                        Task {
                                            try await dbQuery {
                                                try await $0.archiveCourse(courseId: course.id)
                                            }
                                            await fetchData()
                                        }
                                    }
                                }
                            }
                            
                        }
                        .refreshable {
                            await fetchData()
                        }
                        .overlay {
                            if courses.filter({ $0.isArchived == false }) == [] {
                                ContentUnavailableView("No courses", systemImage: "compass.drawing")
                            }
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "slowmo")
                            .symbolEffect(.variableColor.iterative.hideInactiveLayers.nonReversing, options: .repeat(.continuous))
                            .imageScale(.large)
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
                if let archivedCourses = courses?.filter(\.isArchived), !archivedCourses.isEmpty {
                    NavigationLink(destination: ArchivedCoursesView(archivedCourses: archivedCourses)) {
                        Image(systemName: "archivebox")
                    }
                }
                Button(action: {
                    withAnimation {
                        showAddCode.toggle()
                    }
                }) {
                    Image(systemName: showAddCode ? "xmark" : "person.crop.badge.magnifyingglass.fill").contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
                }
                NavigationLink(destination: CreateCourseView(courses: $courses)) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await fetchData()
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
    }
    
    private func fetchData() async {
        let setCourses = try? await dbQuery {
            try await $0.getAllCourses()
        }
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
                    try await dbQuery {
                        try await $0.joinCourse(invitationCode: invitationCode)
                    }
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
