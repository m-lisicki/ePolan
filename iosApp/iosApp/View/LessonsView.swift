//
//  LessonsView.swift
//  iosApp
//
//  Created by Michał Lisicki on 30/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

// TODO: - Rows names should display dates - not courseName
// everything with lessonAndTask.lesson.courseName -> Replace
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
        
        let lessonsSorted = lessons.sorted { formattedDate(from : $0.getClassDateString()) < formattedDate(from : $1.getClassDateString()) }
        
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
                        Task {
                            await fetchLessons()
                        }
                    }
                    if groupedLessons == [:] {
                        VStack {
                            Image(systemName: "person.crop.circle")
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
                CreateLessonView(course: course, showCreate: $showCreate)
                    .transition(.slide)
            }
        }
        .toolbar {
            if let points = points {
                Text("Points: \(points)")
                    .font(.caption)
            }
            NavigationLink(destination: ModifyCourseUsers(course: course)) {
                Image(systemName: "person.2.badge.gearshape.fill")
            }
            Button(action: {
                withAnimation {
                    showCreate.toggle()
                }
            }) {
                Image(systemName: showCreate ? "xmark" :"plus")
            }
        }
        .onReceive(refreshController.refreshSignal) { _ in
                    Task {
                        await fetchLessons()
                    }
                }
        .task {
            await fetchLessons()
        }
    }
    
    private func fetchLessons() async {
        let lessons = try? await OAuthManager.shared.dbCommunicationServices?.getAllLessons(courseId: course.id)
        if let lessons = lessons {
            self.lessons = Set(lessons)
        }
        await fetchData()
    }
    
    private func fetchData() async {
        let points = try? await OAuthManager.shared.dbCommunicationServices?.getPoints(courseId: course.id).intValue
        let pointsArray = try? await OAuthManager.shared.dbCommunicationServices?.getPointsForCourse(courseId: course.id)
        if let points = points {
            self.points = points
        }
        if let pointsArray = pointsArray {
            self.pointsArray = pointsArray.reversed()
        }
    }
    
    @State private var selectionsDeclarationsTuple: [UUID: (Set<ExerciseDto>, Set<DeclarationDto>)] = [:]
    
    @ViewBuilder
    private func lessonView(for lesson: LessonDto, activity: Double?) -> some View {
        if let lessonExercises = lesson.exercises, !lessonExercises.isEmpty {
            if lesson.lessonStatus == .past {
                NavigationLink(destination: TasksAssignedView(title: formattedDate(from: lesson.getClassDateString()), lesson: lesson, exercises: lessonExercises.sortedByNumber(), activity: activity ?? 0)) {
                    Text(formattedDate(from: lesson.getClassDateString()))
                        .font(.headline)
                    Spacer()
                    if let activity = activity {
                        Text("\(activity)")
                    }
                }
            } else if lesson.lessonStatus == .near {
                VStack {
                    if let selection = selectionsDeclarationsTuple[UUID(uuidString: "\(lesson.id)")!] {
                        NavigationLink(destination: TasksDetailView(title: formattedDate(from: lesson.getClassDateString()), lesson: lesson, exercises: lessonExercises.sortedByNumber(), declarations: selection.1 ,selection: selection.0)) {
                            VStack(alignment: .leading) {
                                Text(formattedDate(from: lesson.getClassDateString()))
                                    .font(.headline)
                            }
                        }
                    }
                }.task {
                        let declarations = try? await OAuthManager.shared.dbCommunicationServices?.getAllLessonDeclarations(lessonId: lesson.id)
                        if let declarations = declarations {
                            let selections = Set(declarations.filter { $0.declarationStatus == DeclarationStatus.waiting }.compactMap { $0.exercise })
                            selectionsDeclarationsTuple[UUID(uuidString: "\(lesson.id)")!] = (selections, declarations)
                        }
                    
                }
            } else {
                NavigationLink(destination: CreateLessonExercisesView(lesson: lesson, exercises: lesson.exercises)) {
                    Text(formattedDate(from: lesson.getClassDateString()))
                        .font(.headline)
                }
            }
        } else if lesson.lessonStatus == .future {
            NavigationLink(destination: CreateLessonExercisesView(lesson: lesson)) {
                Text(formattedDate(from: lesson.getClassDateString()))
                    .font(.headline)
            }
        } else {
            Text(formattedDate(from: lesson.getClassDateString()))
                .font(.headline)
        }
    }
}

struct CreateLessonExercisesView: View {
    @State var lesson: LessonDto
    @State var exercises: Set<ExerciseDto>?
    
    @EnvironmentObject var refreshController: RefreshController
    
    var body: some View {
        VStack {
            if let exercises = exercises {
                List(exercises.sortedByNumber(), id: \.id) { exercise in
                    HStack {
                        Text("\(exercise.exerciseNumber). \(exercise.subpoint ?? "")")
                        Spacer()
                        let siblings = exercises.filter {$0.exerciseNumber == exercise.exerciseNumber}
                        let sortedSiblings = siblings.sorted { ($0.subpoint ?? "") < ($1.subpoint ?? "") }
                        
                        if siblings.count == 1 || sortedSiblings.last?.id == exercise.id {
                            HStack {
                                let isOnlyBaseLast = siblings.count == 1 && exercise.subpoint == nil && exercise.exerciseNumber == (exercises.map { $0.exerciseNumber }.max() ?? -1)
                                if siblings.count > 1 || isOnlyBaseLast {
                                    Button { removeExercise(for: exercise)} label: {
                                        Image(systemName: "minus.diamond.fill")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                Button { addSubpoint(to: exercise)} label: {
                                    Image(systemName: "plus.diamond.fill")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
            } else {
                Text("No exercises yet")
            }
            Button("Add exercise") {
                addExercise()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Manage exercises")
        .onDisappear {
            if let exercises = exercises {
                lesson.exercises = exercises
                
                Task {
                    try await OAuthManager.shared.dbCommunicationServices?.postExercises(lesson: lesson)
                }
                refreshController.triggerRefresh()
            }
        }
    }
    
    private func addExercise() {
        let index = (exercises?.map(\.exerciseNumber).max() ?? 0) + 1
        exercises = (exercises ?? []).union([ExerciseDto(classDate: lesson.classDate, groupName: lesson.courseName, exerciseNumber: Int32(index), subpoint: nil)])
    }
    
    private func addSubpoint(to exercise: ExerciseDto) {
        guard var set = exercises else { return }
        
        let siblings = set.filter { $0.exerciseNumber == exercise.exerciseNumber }
        
        if exercise.subpoint == nil {
            // First subpoint (creating a and b at once)
            let first = exercise
            set.remove(first)
            first.subpoint = "a"
            set.insert(first)
            let second = ExerciseDto(classDate: exercise.classDate, groupName: exercise.groupName, exerciseNumber:  exercise.exerciseNumber, subpoint: "b")
            set.insert(second)
            exercises = set
            return
        }
        
        let sortedSiblings = siblings.sorted { ($0.subpoint ?? "") < ($1.subpoint ?? "") }
        
        if let last = sortedSiblings.last, let lastSubpoint = last.subpoint {
            var nextSubpoint: String?

            if let ascii = lastSubpoint.unicodeScalars.first?.value, ascii < 122 {
                nextSubpoint = String(Character(UnicodeScalar(ascii + 1)!))
            } else if lastSubpoint.starts(with: "z") {
                let apostropheCount = lastSubpoint.dropFirst().filter { $0 == "'" }.count
                nextSubpoint = "z" + String(repeating: "'", count: apostropheCount + 1)
            }

            if let nextSubpoint {
                let next = ExerciseDto(
                    classDate: exercise.classDate,
                    groupName: exercise.groupName,
                    exerciseNumber: exercise.exerciseNumber,
                    subpoint: nextSubpoint
                )
                set.insert(next)
            }
        }
        
        exercises = set
    }
        
    
    
    private func removeExercise(for exercise: ExerciseDto) {
        guard var set = exercises else { return }
        
        if set.count == 1 {
            exercises = nil
        }
        
        set.remove(exercise)
        
        let siblings = set.filter { $0.exerciseNumber == exercise.exerciseNumber }
        
        // Last subpoints - converting back to exercise without subpoint
        if siblings.count == 1, let second = siblings.first, second.subpoint != nil {
            set.remove(second)
            second.subpoint = nil
            set.insert(second)
        }
        
        exercises = set
    }
}

struct CreateLessonView: View {
    @EnvironmentObject var refreshController: RefreshController
    let course: CourseDto
    @Binding var showCreate: Bool
    
    @State var date: Date = Date()
    
    var body: some View {
        VStack {
            DatePicker("Lesson Date", selection: $date, displayedComponents: .date)
            Button("Add") {
                Task {
                    //                    try await OAuthManager.shared.dbCommunicationServices?.addLesson(courseId: course.id, exercisesAmount: Int32(exercisesAmount))
                    refreshController.triggerRefresh()
                    showCreate = false
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
            
    }
}
