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
        .environment(RefreshController())
}

enum ViewState {
    case loading
    case loaded
    case empty
    case offlineNotLoaded
    case error(ApiError)
}

extension View {
    func fallbackView(viewState: ViewState, fetchData: @escaping (_ forceRefresh: Bool) async -> Void) -> some View {
        overlay {
            switch viewState {
            case .loading:
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                
            case .empty:
                ContentUnavailableView("No courses", systemImage: "book.closed")
                
            case .offlineNotLoaded:
                ContentUnavailableView {
                    Label("No Internet Connection", systemImage: "wifi.slash")
                } description: {
                    Text("Please check your internet and try again.")
                }
                
            case .loaded:
                EmptyView()
                
            case .error(let error):
                ContentUnavailableView {
                    Label("Something went wrong", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Retry") {
                        Task {
                            await fetchData(true)
                        }
                    }
                }
            }
        }
        
    }
}


struct CourseView: View {
    @State var courses = Array<CourseDto>()
    
    @State var showAddCode = false
    @State var showCreate = false
    @State var coursesHasLoaded = false
    
    @State private var apiError: ApiError?
    
    
    var viewState: ViewState {
        if !networkMonitor.isConnected && !coursesHasLoaded {
            return .offlineNotLoaded
        } else if let error = apiError, networkMonitor.isConnected {
            return .error(error)
        } else if !coursesHasLoaded {
            return .loading
        } else if courses.isEmpty {
            return .empty
        } else {
            return .loaded
        }
    }
    
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    var body: some View {
        NavigationStack {
            VStack {
                List($courses, id: \.id) { $course in
                    //                        if !course.isArchived {
                    NavigationLink(destination: LessonsView(course: course)) {
                        Text(course.name)
                            .font(.headline)
                    }
                    .swipeActions {
                        //                                Button("Archive") {
                        //                                    Task {
                        //                                        try await DBQuery.archiveCourse(courseId: course.id)
                        //                                        await fetchData()
                        //                                    }
                        //                                }
                    }
                    //                        }
                }
                .refreshable {
                    await fetchData(forceRefresh: true)
                }
            }
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
                //                let archivedCourses = courses.filter(\.isArchived)
                //                if !archivedCourses.isEmpty {
                //                    ToolbarItem {
                //                        NavigationLink(destination: ArchivedCoursesView(archivedCourses: archivedCourses)) {
                //                            Image(systemName: "archivebox")
                //                        }
                //                    }
                //                }
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
                    Button(action: { withAnimation { showCreate = true } }) {
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
            .sheet(isPresented: $showCreate) {
                NavigationStack {
                    CreateCourseView(courses: $courses)
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
    
    private func fetchData(forceRefresh: Bool = false) async {
#if !targetEnvironment(simulator)
        do {
            let setCourses = try await DBQuery.getAllCourses(forceRefresh: forceRefresh)
            courses = Array(setCourses).sorted { $0.name < $1.name }
            coursesHasLoaded = true
            apiError = nil
        }  catch let error as ApiError {
            apiError = error
        } catch {
            apiError = .customError("Unexpected error: \(error.localizedDescription)")
        }
#else
        courses = CourseDto.getMockData()
        coursesHasLoaded = true
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

struct ArchivedCoursesView: View {
    let archivedCourses: [CourseDto]
    
    var body: some View {
        List(archivedCourses, id: \.id) { course in
            Text(course.name)
        }
    }
}
