//
//  Day.swift
//  iosApp
//
//  Created by Michał Lisicki on 28/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

import UserNotifications

struct CreateCourseView: View {
    @Binding var courses: Array<CourseDto>?
    
    @State private var name = ""
    @State private var instructorEmail = ""
    @State private var selectedDays = Set<String>()
    @State private var emailInput = ""
    @State private var emails = Array<String>()
    @State private var showingAlert = false
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 7)
    @State private var calendarWeekdaySymbols = Calendar.autoupdatingCurrent.shortWeekdaySymbols
    @State private var repeatInterval = 1
    
    var isFormValid: Bool {
        !name.isEmpty && !instructorEmail.isEmpty && !selectedDays.isEmpty && startDate < endDate && EmailHelper.isEmailValid(instructorEmail)
    }
    
    @Environment(\.dismiss) private var dismiss
    
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
                            .foregroundColor(.white)
                            .frame(minWidth: 50, minHeight: 33)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(isSelected ? Color.accentColor : Color.secondary)
                            )
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedDays)
                            .onTapGesture {
                                if isSelected {
                                    selectedDays.remove(weekday)
                                } else {
                                    selectedDays.insert(weekday)
                                }
                            }
                    }
                }
                Stepper(value: $repeatInterval, in: 1...3) {
                    Text("Every ") + Text(repeatInterval == 1 ? "Week" : "\(repeatInterval) Weeks")
                }
            }
            
            // MARK: - Date Selection
            Section(header: Text("Course Dates")) {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            
            // MARK: - Invite Students
            Section(header: Text("Invite")) {
                TextField("Enter instructor email", text: $instructorEmail)
                HStack {
                    TextField("Enter student email", text: $emailInput)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button("Add") {
                        emails.append(EmailHelper.trimCharacters(emailInput))
                        emailInput = ""
                    }
                    .disabled(!EmailHelper.isEmailValid(emailInput, emails: emails))
                }
                List {
                    ForEach(emails, id: \.self) { email in
                        Text(email)
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    emails.removeAll { $0 == email }
                                }
                                .tint(.red)
                            }
                    }
                }
            }
        }
        .toolbar {
            // MARK: - Done Button
            Button("Done") {
                Task {
                    do {
                        OAuthManager.shared.performActionWithFreshTokens()
                        guard let services = OAuthManager.shared.dbCommunicationServices else {
                            fatalError("No DB Communication Services")
                        }
                        
                        let newCourse = try await services.createCourse(
                            name: name,
                            instructor: instructorEmail,
                            swiftShortSymbols: selectedDays,
                            students: Set(emails),
                            startDateISO: startDate.ISO8601Format(),
                            endDateISO: endDate.ISO8601Format(),
                            frequency: Int32(repeatInterval)
                        )
                        
                        
                        
                        await withThrowingTaskGroup { group in
                            for email in emails {
                                group.addTask {
                                    try await services.addStudent(courseId: newCourse.id,email: EmailHelper.trimCharacters(email))
                                }
                            }
                        }
                        
                        
                        //TODO: - Push notifications
                        //NotificationCentre.scheduleCourseNotification(startDate: startDate, endDate: endDate, courseName: name, weekDay: selectedDays)
                        
                        courses = (courses ?? []) + [newCourse]
                        dismiss()
                    } catch {
                        log.error("\(error)")
                        showingAlert = true
                    }
                }
            }
            .disabled(!isFormValid)
            
        }
        .navigationTitle("Create Course")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text("An unexpected error occurred while creating the course"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
