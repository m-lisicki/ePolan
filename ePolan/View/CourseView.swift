//
//  CourseView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//

import SwiftUI

#Preview {
    BottomBarView()
        .environment(NetworkMonitor())
}

struct CourseView: View, @MainActor FallbackView, PostData {
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
    
    @State var searchText = String()
    
    var searchResults: [CourseDto] {
            if searchText.isEmpty {
                return groupedCourses
            } else {
                return groupedCourses.filter { $0.name.localizedCaseInsensitiveContains(searchText)}
            }
    }
    
    @Namespace private var namespace
    var body: some View {
            VStack {
                List {
                    ForEach(searchResults, id: \.id) { course in
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
                        .padding()
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Archive", systemImage: "archivebox") { showArchived = true  }
                }
#if !os(macOS)
                .matchedTransitionSource(id: "archive", in: namespace)
#endif
                ToolbarSpacer(.fixed)
                    ToolbarItem {
                        Menu("Add Course", systemImage: "person.2.badge.plus") {
                            Button(action: {
                                withAnimation {
                                    showAddCode.toggle()
                                }
                            }) {
                                Label("Join course", systemImage: "person.2.badge.plus")
                            }
                            Button(action: { showCreate = true }) {
                                Label("Create new course", systemImage: "plus.rectangle.on.rectangle")
                            }
                        }
                    }
                    
            }
#if !os(macOS)
            .tabBarMinimizeBehavior(.onScrollDown)
        #endif
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
                            ToolbarItem() {
                                Button("Done", systemImage: "checkmark") {
                                    showArchived = false
                                }
                            }
                        }
                        .environment(refreshController)
                }
#if !os(macOS)
                .navigationTransition(.zoom(sourceID: "archive", in: namespace))
                #endif
            }
            .sheet(isPresented: $showCreate) {
                NavigationStack {
                    CreateCourseView(courses: $data)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel", systemImage: "xmark") {
                                    showCreate = false
                                }
                            }
                        }
                }
            }
    }

    func fetchData(forceRefresh: Bool = false) async {
        #if !DEBUG
            await fetchData(
                forceRefresh: forceRefresh,
                fetchOperation: { try await DBQuery.getAllCourses(forceRefresh: forceRefresh) },
                onError: { error in apiError = error },
            ) {
                data in self.data = data
            }
        #else
        data = Set(CourseDto.getMockData())
            groupedCourses = CourseDto.getMockData()
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

struct ArchivedCoursesView: View, @MainActor FallbackView, PostData {
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
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fallbackView(viewState: viewState)
        .errorAlert(isPresented: $showApiError, error: apiError)
    }

    func fetchData(forceRefresh: Bool = false) async {
        #if !DEBUG
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
