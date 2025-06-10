//
//  CreateCourseView.swift
//  ePolan
//
//  Created by Michał Lisicki on 28/04/2025.
//

import SwiftUI

import UserNotifications

#Preview {
    @Previewable @State var courses: Set<CourseDto>? = Set(CourseDto.getMockData())
    NavigationStack {
        CreateCourseView(courses: $courses)
    }
}


struct CreateCourseView: View {
    @Binding var courses: Set<CourseDto>?

    @State var name = ""
    @State var instructorEmail = ""
    @State var selectedDays = Set<String>()
    @State var emailInput = ""
    @State var emails = [String]()
    @State var startDate: Date = .init()
    @State var endDate: Date = .init().addingTimeInterval(TimeInterval(60 * 60 * 24 * 7))
    @State var calendarWeekdaySymbols = Calendar.autoupdatingCurrent.shortWeekdaySymbols
    @State var repeatInterval = 1
    @State var isPutOngoing = false

    var isFormValid: Bool {
        !name.isEmpty && !instructorEmail.isEmpty && !selectedDays.isEmpty && startDate < endDate && EmailHelper.isEmailValid(instructorEmail)
    }

    @Environment(\.dismiss) var dismiss

    @State var showApiError = false
    @State var apiError: ApiError?

    var body: some View {
        Form {
            // MARK: - Course Details

            Section(header: Text("Course Details")) {
                TextField("Course Name", text: $name)
            }

            // MARK: - Days Selection

            Section(header: Text("Repeat")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 13)], spacing: 13) {
                        ForEach(calendarWeekdaySymbols, id: \.self) { weekday in
                            let isSelected = selectedDays.contains(weekday)
                            Text(weekday)
                                .font(.subheadline)
                                .frame(minWidth: 50, minHeight: 33)
                                .glassEffect(.regular.tint(isSelected ? .blue : .clear).interactive())
                            //                            .background(
                            //                                RoundedRectangle(cornerRadius: 7)
                            //                                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2)),
                            //                            )
                            //                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedDays)
                                .onTapGesture {
                                    if isSelected {
                                        selectedDays.remove(weekday)
                                    } else {
                                        selectedDays.insert(weekday)
                                    }
                                }
                                .accessibilityLabel(Text("\(weekday)\(isSelected ? ", selected" : "")"))
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                Stepper(value: $repeatInterval, in: 1 ... 4) {
                    if repeatInterval == 1 {
                        Text("Every Week")
                    } else {
                        Text("Every \(repeatInterval) Weeks")
                    }
                }
            }

            // MARK: - Date Selection

            Section(header: Text("Course Dates")) {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }

            // MARK: - Invite Students

            Section(header: Text("Invite")) {
                HStack {
                    TextField("Enter instructor email", text: $instructorEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    if let email = UserInformation.shared.email, instructorEmail != email {
                        Button("Me") {
                            instructorEmail = email
                        }
                    }
                }
                HStack {
                    TextField("Enter student email", text: $emailInput)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    Button("Add") {
                        emails.append(EmailHelper.trimCharacters(emailInput))
                        emailInput = ""
                    }
                    .disabled(!EmailHelper.isEmailValid(emailInput, emails: emails))
                }
                List {
                    ForEach(emails, id: \.self) { email in
                        Text(email)
                    }.onDelete { indicies in
                        emails.remove(atOffsets: indicies)
                    }
                }
            }
        }
        .toolbar {
            // MARK: - Done Button

            ToolbarItem(placement: .confirmationAction) {
                if !isPutOngoing {
                    Button("Done", systemImage: "checkmark") {
                        Task {
                            do {
                                isPutOngoing = true
                                let newCourse = try await DBQuery.createCourse(
                                    name: name,
                                    instructor: instructorEmail,
                                    swiftShortSymbols: selectedDays,
                                    students: Set(emails),
                                    startDate: startDate,
                                    endDate: endDate,
                                    frequency: repeatInterval,
                                )

                                    try await withThrowingTaskGroup { group in
                                        for email in emails {
                                            group.addTask {
                                                try await DBQuery.addStudent(courseId: newCourse.id, email: EmailHelper.trimCharacters(email))
                                            }
                                        }
                                        
// TODO: - Problem with concurrency checking using new upcoming features
//                                        try await group.next(isolation: #isolation)
                                    }

                                courses?.insert(newCourse)
                                dismiss()
                            } catch {
                                log.error("\(error)")
                                apiError = error.mapToApiError()
                                showApiError = true
                                isPutOngoing = false
                            }
                        }
                    }
                    .disabled(!isFormValid)
                } else {
                    ProgressView()
                }
            }
        }
        .errorAlert(isPresented: $showApiError, error: apiError)
        .navigationTitle("Create Course")
        .navigationBarTitleDisplayMode(.inline)
    }
}
