//
//  CourseView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//

import SwiftUI

#Preview {
    CourseView()
        .environment(NetworkMonitor())
}

struct CourseView: View, FallbackView, PostData {
    typealias T = CourseDto

    @State var data: Set<CourseDto>? {
        didSet {
            groupedCourses = data?.sorted { $0.name < $1.name } ?? []
        }
    }

    @State var groupedCourses = [CourseDto]()
    @State var showAddCode = false
    @State var showCreate = false
    @State var showArchived = false

    var refreshController = RefreshController()
    @Environment(NetworkMonitor.self) var networkMonitor

    @State var showApiError: Bool = false
    @State var isPutOngoing = false
    @State var apiError: ApiError?

    var body: some View {
        NavigationStack {
            VStack {
                List($groupedCourses, id: \.id) { $course in
                    NavigationLink(destination: LessonsView(course: course).environment(refreshController)) {
                        Text(course.name)
                            .font(.headline)
                    }
                    .swipeActions {
                        Button("Archive") {
                            Task {
                                await postInformation(
                                    postOperation: { try await DBQuery.archiveCourse(courseId: course.id) },
                                    onError: { error in apiError = error },
                                ) { data?.remove(course) }
                            }
                        }
                    }
                }
                .refreshable {
                    await fetchData(forceRefresh: true)
                }
            }
            .errorAlert(isPresented: $showApiError, error: apiError)
            .fallbackView(viewState: viewState)
            .navigationTitle("Courses")
            .overlay(alignment: .bottom) {
                if showAddCode {
                    JoinCourseView(isAddCodeShown: $showAddCode)
                        .transition(.slide)
                        .background(.thinMaterial)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: { showArchived = true }) {
                        Image(systemName: "archivebox")
                    }
                }
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
                    Button(action: { showCreate = true }) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                    }
                    .accessibilityLabel("Add new course")
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
            .onReceive(refreshController.refreshSignalCourses) { _ in
                Task {
                    await fetchData()
                }
            }
            .sheet(isPresented: $showArchived) {
                NavigationStack {
                    ArchivedCoursesView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showArchived = false
                                }
                            }
                        }
                        .environment(refreshController)
                }
            }
            .sheet(isPresented: $showCreate) {
                NavigationStack {
                    CreateCourseView(courses: $groupedCourses)
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

    func fetchData(forceRefresh: Bool = false) async {
        #if true
            await fetchData(
                forceRefresh: forceRefresh,
                fetchOperation: { try await DBQuery.getAllCourses(forceRefresh: forceRefresh) },
                onError: { error in apiError = error },
            ) {
                data in self.data = data
            }
        #else
            data = Set(CourseDto.getMockData())
        #endif
    }
}

struct JoinCourseView: View, PostData {
    @State var apiError: ApiError?

    @State var isPutOngoing = false
    @State var showApiError = false

    @Environment(NetworkMonitor.self) var networkMonitor
    @State var invitationCode: String = ""
    @Binding var isAddCodeShown: Bool

    var body: some View {
        HStack {
            TextField("Enter invitation code", text: $invitationCode)
            Button("Join") {
                Task {
                    await postInformation(
                        postOperation: { try await DBQuery.joinCourse(invitationCode: invitationCode) },
                        onError: { error in apiError = error },
                        logicAfterSuccess: {
                            withAnimation {
                                isAddCodeShown = false
                            }
                        },
                    )
                }
            }
            .replacedWithProgressView(isPutOngoing: isPutOngoing)
        }
        .padding()
    }
}

struct ArchivedCoursesView: View, FallbackView, PostData {
    typealias T = CourseDto

    @State var data: Set<CourseDto>? {
        didSet {
            groupedCourses = data?.sorted { $0.name < $1.name } ?? []
        }
    }

    @State var groupedCourses = [CourseDto]()

    @Environment(NetworkMonitor.self) var networkMonitor
    @Environment(RefreshController.self) var refreshController

    @State var showApiError: Bool = false
    @State var isPutOngoing = false
    @State var apiError: ApiError?

    var body: some View {
        VStack {
            List(groupedCourses, id: \.id) { course in
                Text(course.name)
                    .swipeActions {
                        Button("Unarchive") {
                            Task {
                                await postInformation(
                                    postOperation: { try await DBQuery.unarchiveCourse(courseId: course.id) },
                                    onError: { error in apiError = error },
                                ) { data?.remove(course)
                                    refreshController.triggerRefreshCourses()
                                }
                            }
                        }
                    }
            }
            .task {
                await fetchData()
            }
            .refreshable {
                await fetchData(forceRefresh: true)
            }
        }
        .navigationTitle("Archived Courses")
        .navigationBarTitleDisplayMode(.inline)
        .fallbackView(viewState: viewState)
        .errorAlert(isPresented: $showApiError, error: apiError)
    }

    func fetchData(forceRefresh: Bool = false) async {
        #if true
            await fetchData(
                forceRefresh: forceRefresh,
                fetchOperation: { try await DBQuery.getArchivedCourses() },
                onError: { error in apiError = error },
            ) {
                data in self.data = data
            }
        #else
            data = Set(CourseDto.getMockData())
        #endif
    }
}
