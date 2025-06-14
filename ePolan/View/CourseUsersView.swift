//
//  CourseUsersView.swift
//  ePolan
//
//  Created by Michał Lisicki on 02/05/2025.
//

import SwiftUI

#Preview {
    CourseUsersView(course: CourseDto.getMockData().first!)
        .environment(NetworkMonitor())
}

struct CourseUsersView: View, FallbackView, PostData {
    @State var isPutOngoing = false

    typealias T = String

    let course: CourseDto

    @State var data: Set<String>? {
        didSet {
            users = data?.sorted(by: <) ?? []
        }
    }

    @State var users: [String] = []
    @State var email: String = ""

    var currentUser: String {
        UserInformation.shared.email ?? ""
    }

    @State var showApiError: Bool = false
    @State var apiError: ApiError?

    @Environment(NetworkMonitor.self) var networkMonitor

    var body: some View {
        VStack {
            List(users, id: \.self) { user in
                Text(user)
                    .bold(user == currentUser)
                    .swipeActions {
                        if user != currentUser, UserInformation.shared.isAuthorised(user: course.creator) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await removeUser(email: user)
                                }
                            }
                            .tint(.red)
                        }
                    }
            }
            .errorAlert(isPresented: $showApiError, error: apiError)
            .fallbackView(viewState: viewState)
            if UserInformation.shared.isAuthorised(user: course.creator) {
                HStack {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
#if !os(macOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    #endif
                    Button("Add") {
                        Task {
                            await addUser(email: EmailHelper.trimCharacters(email))
                        }
                    }
                    .replacedWithProgressView(isPutOngoing: isPutOngoing)
                    .buttonStyle(.borderedProminent)
                    .disabled(!EmailHelper.isEmailValid(email) || users.contains(EmailHelper.trimCharacters(email)))
                }
                .padding()
            }
            HStack {
                VStack(alignment: .leading) {
                    Text("Invitation code:")
                        .font(.subheadline)
                    Text(course.courseCode)
                        .font(.caption)
                        .draggable(course.courseCode)
                }
                Spacer()
                Button("Copy") {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(course.courseCode, forType: .string)
                    #else
                    UIPasteboard.general.string = course.courseCode
                    #endif
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onChange(of: networkMonitor.isConnected) {
            Task {
                await fetchData()
            }
        }
        .navigationTitle("Course users")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            if networkMonitor.isConnected {
                await fetchData()
            }
        }
    }

    func fetchData(forceRefresh: Bool = false) async {
        #if !DEBUG
            await fetchData(
                forceRefresh: forceRefresh,
                fetchOperation: { try await DBQuery.getAllStudents(courseId: course.id) },
                onError: { error in apiError = error },
            ) {
                data in self.data = data
            }
        #else
            data = Set(["Dr. Strangelove", "David Bowie", "Witkacy"])
        #endif
    }

    func addUser(email: String) async {
        await postInformation(
            postOperation: { try await DBQuery.addStudent(courseId: course.id, email: email) },
            onError: { error in apiError = error },
        ) {
            data?.insert(email)
            self.email = ""
        }
    }

    func removeUser(email: String) async {
        await postInformation(
            postOperation: { try await DBQuery.removeStudent(courseId: course.id, email: email) },
            onError: { error in apiError = error },
        ) { users.removeAll { $0 == email }
        }
    }
}
