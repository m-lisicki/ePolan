//
//  PointsView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

let postsService = Posts()

struct CourseView: View {
    let courses = MockDataKt.mockCourseDto
    
    var body: some View {
        NavigationStack {
            List([courses], id: \.id) { course in
                NavigationLink(destination: PointsView(course: course)) {
                    Text(course.name)
                        .font(.headline)
                }
            }
            .navigationTitle("Courses")
            .toolbar {
                NavigationLink(destination: CreateCourseView()) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

enum status: String {
    case upcoming = "Upcoming"
    case ongoing = "Ongoing"
}

struct LessonAndTasks {
    let lesson: LessonDto
    let exercises: Array<ExerciseDto>?
}

// TODO: - Rows names should display dates - not courseName
// everything with lessonAndTask.lesson.courseName -> Replace
struct PointsView: View {
    let course: CourseDto
    @State var lessons = Array<LessonAndTasks>()
    
    private var groupedLessons: [String: [LessonAndTasks]] {
        Dictionary(grouping: lessons) { lesson in
            // TODO: - your Date logic segregation here
            status.ongoing.rawValue
            //lesson.lesson.classDate.date ?? Date() > Date() ? status.upcoming.rawValue : status.ongoing.rawValue
        }
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(groupedLessons.keys.sorted(), id: \.self) { key in
                    Section(header: Text(key)) {
                        ForEach(groupedLessons[key] ?? [], id: \.lesson.id) { lessonAndTask in
                            if let lessonTasks = lessonAndTask.exercises {
                                if key == status.ongoing.rawValue {
                                    // Exercises Assigned
                                    NavigationLink(destination: TasksAssignedView(title: lessonAndTask.lesson.courseName,tasks: lessonTasks)) {
                                        Text(lessonAndTask.lesson.courseName)
                                            .font(.headline)
                                    }
                                } else {
                                    // Exercises Declaration Ongoing
                                    NavigationLink(destination: TasksDetailView(exercises: lessonTasks, name: lessonAndTask.lesson.courseName)) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(lessonAndTask.lesson.courseName)
                                                    .font(.headline)
                                            }
                                        }
                                    }
                                }
                            } else {
                                // Exercises not yet created
                                Text(lessonAndTask.lesson.courseName)
                                    .font(.headline)
                            }
                        }
                    }
                    
                    
                }
            }
        }
        .onAppear {
            //TODO: - fetch real Tasks
            lessons = [LessonAndTasks(lesson: Array(course.lessons)[0], exercises: MockDataKt.mockExerciseDtos), LessonAndTasks(lesson: Array(course.lessons)[1], exercises: MockDataKt.mockExerciseDtos)]
        }
    }
}
