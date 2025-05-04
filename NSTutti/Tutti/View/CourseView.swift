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
                                            try await OAuthManager.shared.dbCommunicationServices?.archiveCourse(courseId: course.id)
                                            await fetchData()
                                        }
                                    }
                                }
                            }
                            
                        }
                        .refreshable {
                            await fetchData()
                        }
                        if courses.filter({ $0.isArchived == false }) == []{
                            VStack {
                                Image(systemName: "compass.drawing")
                                    .imageScale(.large)
                                    .symbolRenderingMode(.palette)
                                Text("No courses")
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
            .toolbar {
                if let archivedCourses = courses?.filter(\.isArchived), !archivedCourses.isEmpty {
                    NavigationLink(destination: ArchivedCoursesView(archivedCourses: archivedCourses)) {
                        Image(systemName: "archivebox")
                    }
                }
                NavigationLink(destination: CreateCourseView(courses: $courses)) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await fetchData()
        }
    }
    
    private func fetchData() async {
        let setCourses = try? await OAuthManager.shared.dbCommunicationServices?.getAllCourses()
        if let setCourses = setCourses {
            courses = Array(setCourses).sorted { $0.name < $1.name }
        }
    }
}

struct ArchivedCoursesView: View {
    let archivedCourses: [CourseDto]
    
    var body: some View {
        List(archivedCourses, id: \.id) { course in
            Text(course.name)
        }
        .padding()
    }
}
