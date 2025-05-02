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
    @EnvironmentObject var refreshController: RefreshController

    var body: some View {
        NavigationStack {
            VStack {
                if let courses = courses {
                    ZStack {
                        List(courses, id: \.id) { course in
                            NavigationLink(destination: LessonsView(course: course)) {
                                    Text(course.name)
                                        .font(.headline)
                                }
                        }
                        .refreshable {
                            await fetchData()
                        }
                        if courses == [] {
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
