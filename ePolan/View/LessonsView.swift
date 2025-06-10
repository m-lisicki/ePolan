//
//  LessonsView.swift
//  ePolan
//
//  Created by Michał Lisicki on 30/04/2025.
//

import SwiftUI

#Preview {
    NavigationStack {
        LessonsView(course: CourseDto.getMockData().first!)
    }
    .environment(NetworkMonitor())
    .environment(RefreshController())
}

struct LessonsView: View, FallbackView, PostData {
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
    @State var apiError: ApiError?
    @State var isPutOngoing = false
    @State var showApiError = false
    @State var showUsers = false
    static let statusOrder = ["Future", "Near", "Past"]
    let lessonStatusArray = LessonStatus.allCases
    var body: some View {
                List {
                    ForEach(lessonStatusArray.indices, id: \.self) { i in
                        Section {
                            DisclosureGroup(
                                isExpanded: $isExpanded[i],
                                content: {
                                    ForEach(groupedLessons[lessonStatusArray[i].rawValue] ?? [], id: \.self) { lesson in
                                        lessonView(for: lesson, activity: lessonActivity(for: lesson))
                                            .swipeActions {
                                                if UserInformation.shared.isAuthorised(user: course.creator) {
                                                    Button("Delete", role: .destructive) {
                                                        Task {
                                                            do {
                                                                try await deleteLesson(lesson: lesson)
                                                            } catch {
                                                                apiError = error.mapToApiError()
                                                                showApiError = true
                                                            }
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
                                },
                            )
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(BackgroundGradient())
                .refreshable {
                    await fetchLessons(forceRefresh: true)
                    await fetchActivity(forceRefresh: true)
                }
                .errorAlert(isPresented: $showApiError, error: apiError)
            .fallbackView(viewState: viewState)
            .overlay(alignment: .bottom) {
                if showCreate {
                    CreateLessonView(courseId: course.id, showCreate: $showCreate)
                        .transition(.slide)
                        .environment(refreshController)
                        .glassEffect()
                        .padding()
                }
            }
        .sheet(isPresented: $showCharts) {
            NavigationStack {
                ChartsView(pointsArray: pointsArray)
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button("Done", systemImage: "checkmark") {
                                showCharts = false
                            }
                        }
                    }
                    .presentationDetents([.medium])
            }
        }
        .task {
            async let lessonsTask: () = fetchLessons()
            async let activityTask: () = fetchActivity()

            await lessonsTask
            await activityTask
        }
        .sheet(isPresented: $showUsers) {
            NavigationStack {
                CourseUsersView(course: course)
                    .toolbar {
                        Button("Done", systemImage: "checkmark") {
                            showUsers = false
                        }
                    }
            }
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
                Button("Show course members", systemImage: UserInformation.shared.isAuthorised(user: course.creator) ? "person.2.badge.gearshape" : "person.2") {
                    showUsers.toggle()
                }
            }
            if UserInformation.shared.isAuthorised(user: course.creator) {
                ToolbarItem {
                    Button(action: {
                        withAnimation {
                            showCreate.toggle()
                        }
                    }) {
                        Image(systemName: showCreate ? "xmark" : "plus").contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
                    }
                }
            }
        }
        .onReceive(refreshController.refreshSignalActivity) { _ in
            Task {
                try await ApiClient.shared.removeCachedResponse(for: DBQuery.makeRequest(url: DBQuery.getPointsForCourseURL(course.id), method: .GET))
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
        .navigationTitle("Lessons")
        .navigationBarTitleDisplayMode(.inline)
    }

    func deleteLesson(lesson: LessonDto) async throws {
        try await DBQuery.deleteLesson(lessonId: lesson.id, courseId: course.id)

        data?.remove(lesson)
    }

    func lessonActivity(for lesson: LessonDto) -> Double {
        pointsArray.first { $0.lesson == lesson }?.activityValue ?? 0
    }

    func formattedDate(from date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    func fetchLessons(forceRefresh: Bool = false) async {
        #if !DEBUG
            await fetchData(
                forceRefresh: forceRefresh,
                fetchOperation: { try await DBQuery.getAllLessons(courseId: course.id, forceRefresh: forceRefresh) },
                onError: { error in apiError = error },
            ) {
                data in self.data = data
            }
        #else
            data = Set(LessonDto.getMockData())
        #endif
    }

    func fetchActivity(forceRefresh: Bool = false) async {
        #if !DEBUG
            await fetchData(
                forceRefresh: forceRefresh,
                fetchOperation: { try await DBQuery.getPointsForCourse(courseId: course.id, forceRefresh: forceRefresh) },
                onError: { error in apiError = error },
            ) {
                data in pointsArray = data.reversed()
            }
        #else
            pointsArray = PointDto.getMockData()
        #endif
    }

    @ViewBuilder
    func lessonView(for lesson: LessonDto, activity: Double) -> some View {
        switch lesson.status {
        case .past:
            NavigationLink(destination: TasksAssignedView(title: formattedDate(from: lesson.classDate), lesson: lesson, courseId: course.id, activity: activity).environment(refreshController)) {
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
        case .near:
            if lesson.exercises.isEmpty {
                if UserInformation.shared.isAuthorised(user: course.creator) {
                    NavigationLink(destination: TasksManagementView(lesson: lesson, courseID: course.id)) {
                        Text(formattedDate(from: lesson.classDate))
                            .font(.headline)
                    }
                } else {
                    HStack {
                        Text(formattedDate(from: lesson.classDate))
                            .font(.headline)
                        Spacer()
                        Image(systemName: "pencil.slash").symbolRenderingMode(.palette)
                    }
                }
            } else {
                NavigationLink(destination: TasksAssignView(title: formattedDate(from: lesson.classDate), lessonId: lesson.id, data: lesson.exercises)) {
                    VStack(alignment: .leading) {
                        Text(formattedDate(from: lesson.classDate))
                            .font(.headline)
                    }
                }
                .accessibilityHint("Declare exercises")
            }
        case .future:
            if UserInformation.shared.isAuthorised(user: course.creator) {
                NavigationLink(destination: TasksManagementView(lesson: lesson, courseID: course.id)) {
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

struct CreateLessonView: View, PostData {
    @State var isPutOngoing = false

    let courseId: UUID

    @Binding var showCreate: Bool

    @State var date: Date = .init()

    @State var showApiError: Bool = false
    @Environment(RefreshController.self) var refreshController
    @Environment(NetworkMonitor.self) var networkMonitor

    var body: some View {
        HStack {
            DatePicker("Lesson Date", selection: $date, displayedComponents: .date)
            Button("Add") {
                Task {
                    await postInformation(postOperation: { try await DBQuery.manualAddLesson(courseId: courseId, date: date) },
                                          onError: { _ in showApiError = true }, logicAfterSuccess: {
                                              refreshController.triggerRefreshLessons()
                                              withAnimation {
                                                  showCreate = false
                                              }
                                          })
                }
            }
            .replacedWithProgressView(isPutOngoing: isPutOngoing)
            .alert("Unable to add lesson", isPresented: $showApiError) {}
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
