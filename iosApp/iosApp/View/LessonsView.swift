//
//  LessonsView.swift
//  iosApp
//
//  Created by Michał Lisicki on 30/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

struct LessonsView: View {
    let course: CourseDto
    @State var lessons: Set<LessonDto>?
    @State var points: Int?
    @State var pointsArray: Array<PointDto>?
    
    @State var showCreate = false
    @EnvironmentObject var refreshController: RefreshController
    
    var groupedLessons: [String: [LessonDto]]? {
        var groupedLessons = Dictionary<String, [LessonDto]>()
        
        guard let lessons = lessons else { return nil }
        
        let lessonsSorted = lessons.sorted { formattedDate(from : $0.getClassDateString()) > formattedDate(from : $1.getClassDateString()) }
        
        for lesson in lessonsSorted {
            if groupedLessons[lesson.statusText] == nil {
                groupedLessons[lesson.statusText] = []
            }
            
            groupedLessons[lesson.statusText]?.append(lesson)
        }
        
        return groupedLessons
    }
    
    private func lessonActivity(for lesson: LessonDto) -> Double? {
        pointsArray?.first{ $0.lesson == lesson }?.activityValue
    }
    
    func formattedDate(from isoString: String) -> String {
        if let date = ISO8601DateFormatter().date(from: isoString) {
            return date.formatted(date: .abbreviated, time: .omitted)
        } else {
            return "Invalid date"
        }
    }
    
    var body: some View {
        VStack {
            if let groupedLessons = groupedLessons {
                ZStack {
                    List {
                        ForEach(groupedLessons.keys.sorted(), id: \.self) { status in
                            Section(header: Text(status)) {
                                ForEach(groupedLessons[status] ?? [], id: \.self) { lesson in
                                    lessonView(for: lesson, activity: lessonActivity(for: lesson))
                                        .swipeActions {
                                            Button("Delete", role: .destructive) {
                                                Task {
                                                    try await OAuthManager.shared.dbCommunicationServices?.deleteLesson(lessonId: lesson.id)
                                                    await fetchLessons()
                                                }
                                            }
                                            .tint(.red)
                                        }
                                }
                            }
                        }
                    }
                    .refreshable {
                        await fetchLessons()
                    }
                    if groupedLessons == [:] {
                        VStack {
                            Image(systemName: "person.3").symbolRenderingMode(.palette)
                                .imageScale(.large)
                            Text("No lessons")
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
            if showCreate {
                CreateLessonView(course: course, lessons: $lessons, showCreate: $showCreate)
                    .transition(.slide)
            }
        }
        .toolbar {
            if let points = points {
                Text("Points: \(points)")
                    .font(.caption)
            }
            NavigationLink(destination: ModifyCourseUsers(course: course)) {
                Image(systemName: "person.2.badge.gearshape.fill").symbolRenderingMode(.palette)
            }
            Button(action: {
                withAnimation {
                    showCreate.toggle()
                }
            }) {
                Image(systemName: showCreate ? "xmark" :"plus").contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
            }
        }
        .onReceive(refreshController.refreshSignalExercises) { _ in
                    Task {
                        await fetchLessons()
                    }
                }
        .onReceive(refreshController.refreshSignalActivity) { _ in
            Task {
                await fetchActivity()
            }
        }
        .task {
            async let lessonsTask: () = fetchLessons()
            async let activityTask: () = fetchActivity()

            await lessonsTask
            await activityTask
        }
    }
    
    private func fetchLessons() async {
        let lessons = try? await OAuthManager.shared.dbCommunicationServices?.getAllLessons(courseId: course.id)
        if let lessons = lessons {
            self.lessons = Set(lessons)
        }
    }
    
    private func fetchActivity() async {
        async let points = OAuthManager.shared.dbCommunicationServices?.getPoints(courseId: course.id).intValue
        async let pointsArray = OAuthManager.shared.dbCommunicationServices?.getPointsForCourse(courseId: course.id)
        if let points = try? await points {
            self.points = points
        }
        if let pointsArray = try? await pointsArray {
            self.pointsArray = pointsArray.reversed()
        }
    }
        
    @ViewBuilder
    private func lessonView(for lesson: LessonDto, activity: Double?) -> some View {
        if let lessonExercises = lesson.exercises {
            if lesson.lessonStatus == .past {
                NavigationLink(destination: TasksAssignedView(title: formattedDate(from: lesson.getClassDateString()), lesson: lesson, exercises: lessonExercises.sortedByNumber(), activity: activity)) {
                    Text(formattedDate(from: lesson.getClassDateString()))
                        .font(.headline)
                    Spacer()
                    if let activity = activity {
                        Text("\(activity)")
                    }
                }
            } else if lesson.lessonStatus == .near {
                if !lessonExercises.isEmpty {
                        NavigationLink(destination: TasksAssignView(title: formattedDate(from: lesson.getClassDateString()), lesson: lesson, exercises: lessonExercises.sortedByNumber())) {
                            VStack(alignment: .leading) {
                                Text(formattedDate(from: lesson.getClassDateString()))
                                    .font(.headline)
                            }
                        }
                        
                    
                } else {
                    HStack {
                        Text(formattedDate(from: lesson.getClassDateString()))
                            .font(.headline)
                        Spacer()
                        Image(systemName: "pencil.slash").symbolRenderingMode(.palette)
                    }
                }
            } else {
                NavigationLink(destination: TasksManagementView(lesson: lesson, exercises: lessonExercises)) {
                    Text(formattedDate(from: lesson.getClassDateString()))
                        .font(.headline)
                }
            }
        } else {
            Text(formattedDate(from: lesson.getClassDateString()))
                .font(.headline)
            Spacer()
            Image(systemName: "exclamationmark.octagon")
                .symbolRenderingMode(.multicolor)
        }
    }
}

struct CreateLessonView: View {
    @EnvironmentObject var refreshController: RefreshController
    let course: CourseDto
    @Binding var lessons: Set<LessonDto>?
    @Binding var showCreate: Bool
    
    @State var date: Date = Date()
    
    var body: some View {
        VStack {
            DatePicker("Lesson Date", selection: $date, displayedComponents: .date)
            Button("Add") {
                Task {
                    //TODO: - Implement data sending
                    //let newLesson = try await OAuthManager.shared.dbCommunicationServices?.addLesson(courseId: course.id, exercisesAmount: Int32(exercisesAmount))
                    showCreate = false
                    
                    //lessons = lessons.append(newLesson)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
            
    }
}
