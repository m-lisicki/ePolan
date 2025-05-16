//
//  LessonsView.swift
//  ePolan
//
//  Created by Michał Lisicki on 30/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

#Preview {
    NavigationStack {
        LessonsView(course: CourseDto.getMockData().first!)
    }
    .environment(OAuthManager.shared)
    .environment(NetworkMonitor())
}

struct LessonsView: View, FallbackView {
    typealias T = LessonDto
        
    let course: CourseDto
    
    @Environment(NetworkMonitor.self) var networkMonitor
    @Environment(RefreshController.self) var refreshController

    @State var data: Set<LessonDto>? {
        didSet {
            groupedLessons =
            data?
                .sorted { $0.classDate > $1.classDate }
                .reduce(into: [:]) {
                    $0[$1.status.rawValue, default: []].append($1)
                } ?? [:]
        }
    }
    
    @State var pointsArray = [PointDto]()
    @State var showCharts = false
    @State var showCreate = false
    @State var isExpanded = [false, true, true]
    @State var groupedLessons = [String: [LessonDto]]()
    
    @State var showApiError: Bool = false
    @State var apiError: ApiError? {
        didSet {
            if networkMonitor.isConnected {
                showApiError = true
            }
        }
    }
    
    nonisolated static let statusOrder = ["Future", "Declarations", "Past"]
    let lessonStatusArray = LessonStatus.allCases
 
    var body: some View {
        VStack {
            ZStack {
                List {
                    ForEach(lessonStatusArray.indices, id: \.self) { i in
                        Section {
                            DisclosureGroup(
                                isExpanded: $isExpanded[i],
                                content: {
                                    ForEach(groupedLessons[lessonStatusArray[i].rawValue] ?? [], id: \.self) { lesson in
                                        lessonView(for: lesson, activity: lessonActivity(for: lesson))
                                            .swipeActions {
                                                if OAuthManager.shared.isAuthorised(user: course.creator) {
                                                    Button("Delete", role: .destructive) {
                                                        Task {
                                                            try await deleteLesson(lesson: lesson)
                                                        }
                                                    }
                                                    .tint(.red)
                                                }
                                            }
                                    }
                                },
                                label: {
                                    Text(Self.statusOrder[i])
                                        .font(.headline)
                                })
                        }
                    }
                    
                }
                .refreshable {
                    await fetchLessons(forceRefresh: true)
                    await fetchActivity(forceRefresh: true)
                }
            }
            .fallbackView(viewState: viewState, fetchData: fetchLessons)
            .overlay(alignment: .bottom) {
                if showCreate {
                    CreateLessonView(courseId: course.id, showCreate: $showCreate)
                        .transition(.slide)
                        .background(.thinMaterial)
                        .environment(refreshController)
                }
            }
        }
        .sheet(isPresented: $showCharts) {
            NavigationStack {
                ChartsView(pointsArray: pointsArray)
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button("Done") {
                                showCharts = false
                            }
                        }
                    }
            }
        }
        .task {
            async let lessonsTask: () = fetchLessons()
            async let activityTask: () = fetchActivity()
            
            await lessonsTask
            await activityTask
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showCharts = true
                } label: {
                    Image(systemName: "chart.bar")
                }
                .accessibilityLabel("Show activity statistics")
            }
            ToolbarItem {
                NavigationLink(destination: CourseUsers(course: course)) {
                    Image(systemName: OAuthManager.shared.isAuthorised(user: course.creator) ? "person.2.badge.gearshape" : "person.2").symbolRenderingMode(.palette)
                }
                .accessibilityLabel("Show course members")
            }
            if OAuthManager.shared.isAuthorised(user: course.creator) {
                ToolbarItem {
                    Button(action: {
                        withAnimation {
                            showCreate.toggle()
                        }
                    }) {
                        Image(systemName: showCreate ? "xmark" :"plus").contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
                    }
                }
            }
        }
        .onReceive(refreshController.refreshSignalActivity) { _ in
            Task {
                await fetchActivity()
            }
        }
        .onReceive(refreshController.refreshSignalLessons) { _ in
            Task {
                await fetchLessons()
            }
        }
        .onChange(of: networkMonitor.isConnected) {
            Task {
                async let lessonsTask: () = fetchLessons()
                async let activityTask: () = fetchActivity()
                
                await lessonsTask
                await activityTask
            }
        }
        .errorAlert(isPresented: $showApiError, error: apiError)
        .navigationTitle("Lessons")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteLesson(lesson: LessonDto) async throws {
        try await DBQuery.deleteLesson(lessonId: lesson.id, courseId: course.id)
        
        data?.remove(lesson)
    }
    
    private func lessonActivity(for lesson: LessonDto) -> Double {
        pointsArray.first{ $0.lesson == lesson }?.activityValue ?? 0
    }
    
    private func formattedDate(from date: Date) -> String {
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func fetchLessons(forceRefresh: Bool = false) async {
#if !targetEnvironment(simulator)
        do {
            data = try await DBQuery.getAllLessons(courseId: course.id, forceRefresh: forceRefresh)
        } catch {
            apiError = error.mapToApiError()
        }
#else
        data = Set(LessonDto.getMockData())
#endif
    }
    
    private func fetchActivity(forceRefresh: Bool = false) async {
#if !targetEnvironment(simulator)
        do {
            let pointsArray = try await DBQuery.getPointsForCourse(courseId: course.id, forceRefresh: forceRefresh)
            self.pointsArray = pointsArray.reversed()
        } catch {
            apiError = error.mapToApiError()
        }
#else
        pointsArray = PointDto.getMockData()
#endif
    }
    
    @ViewBuilder
    private func lessonView(for lesson: LessonDto, activity: Double) -> some View {
        if lesson.status == .past {
            //TODO: - EDGE CASE WHEN ASSIGNED BUT NOT so past :>
            NavigationLink(destination: TasksAssignedView(title: formattedDate(from: lesson.classDate), lesson: lesson, courseId: course.id, activity: activity)                        .environment(refreshController)) {
                HStack {
                    Text(formattedDate(from: lesson.classDate))
                        .font(.headline)
                        .foregroundStyle(.accent)
                    Spacer()
                    Text(String(format: "%.1f", activity))
                        .accessibilityLabel("\(String(format: "%.1f", activity)) points")
                }
            }
            .accessibilityHint("Check assigned tasks")
        } else if lesson.status == .near {
            if !lesson.exercises.isEmpty {
                NavigationLink(destination: TasksAssignView(title: formattedDate(from: lesson.classDate), lessonId: lesson.id, exercises: lesson.exercises.sortedByNumber())) {
                    VStack(alignment: .leading) {
                        Text(formattedDate(from: lesson.classDate))
                            .font(.headline)
                    }
                }
                .accessibilityHint("Declare exercises")
            } else {
                HStack {
                    Text(formattedDate(from: lesson.classDate))
                        .font(.headline)
                    Spacer()
                    Image(systemName: "pencil.slash").symbolRenderingMode(.palette)
                }
            }
        } else {
            if OAuthManager.shared.isAuthorised(user: course.creator) {
                NavigationLink(destination: TasksManagementView(lesson: lesson)) {
                    Text(formattedDate(from: lesson.classDate))
                        .font(.headline)
                }
            } else {
                Text(formattedDate(from: lesson.classDate))
                    .font(.headline)
            }
        }
    }
}

struct CreateLessonView: View {
    let courseId: UUID
    
    @Binding var showCreate: Bool
    
    @State var date: Date = Date()
    
    @State var showApiError: Bool = false
    @Environment(RefreshController.self) var refreshController

    var body: some View {
        HStack {
            DatePicker("Lesson Date", selection: $date, displayedComponents: .date)
            Button("Add") {
                Task {
                do {
                    try await DBQuery.manualAddLesson(courseId: courseId, date: date)
                    refreshController.triggerRefreshLessons()
                    withAnimation {
                        showCreate = false
                    }
                } catch {
                    showApiError = true
                }
                }
            }
            .alert("Unable to add lesson", isPresented: $showApiError) {}
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
