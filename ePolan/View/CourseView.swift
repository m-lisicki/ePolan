//
//  CourseView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

#Preview {
    CourseView()
        .environment(NetworkMonitor())
}


struct CourseView: View, FallbackView {
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

    @State var showApiError: Bool = false
    @State var apiError: ApiError? {
        didSet {
            if networkMonitor.isConnected {
                showApiError = true
            }
        }
    }
    
    @Environment(NetworkMonitor.self) var networkMonitor
    
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
                                do {
                                    try await DBQuery.archiveCourse(courseId: course.id)
                                    data?.remove(course)
                                } catch {
                                    apiError = error.mapToApiError()
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
            .fallbackView(viewState: viewState, fetchData: fetchData)
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
#if !targetEnvironment(simulator)
        do {
            data = try await DBQuery.getAllCourses(forceRefresh: forceRefresh)
        }  catch {
            apiError = error.mapToApiError()
        }
#else
        data = Set(CourseDto.getMockData())
#endif
    }
}

struct JoinCourseView: View {
    @State var invitationCode: String = ""
    @Binding var isAddCodeShown: Bool
    
    var body: some View {
        HStack {
            TextField("Enter invitation code", text: $invitationCode)
            Button("Join") {
                Task {
                    try await DBQuery.joinCourse(invitationCode: invitationCode)
                }
                withAnimation {
                    isAddCodeShown = false
                }
            }
        }
        .padding()
    }
}

struct ArchivedCoursesView: View, FallbackView {
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
    @State var apiError: ApiError? {
        didSet {
            if networkMonitor.isConnected {
                showApiError = true
            }
        }
    }
    
    
    var body: some View {
        VStack {
            List(groupedCourses, id: \.id) { course in
                Text(course.name)
                    .swipeActions {
                        Button("Unarchive") {
                            Task {
                                do {
                                    try await DBQuery.unarchiveCourse(courseId: course.id)
                                    data?.remove(course)
                                    refreshController.triggerRefreshCourses()
                                } catch {
                                    apiError = error.mapToApiError()
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
        .fallbackView(viewState: viewState, fetchData: fetchData)
        .errorAlert(isPresented: $showApiError, error: apiError)
    }
    
    func fetchData(forceRefresh: Bool = false) async {
#if !targetEnvironment(simulator)
        do {
            data = try await DBQuery.getArchivedCourses()
        } catch {
            apiError = error.mapToApiError()
        }
#else
        data = Set(CourseDto.getMockData())
#endif
    }
}
