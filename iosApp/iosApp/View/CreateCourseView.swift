//
//  Day.swift
//  iosApp
//
//  Created by Michał Lisicki on 28/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

#Preview {
    ContentView()
}

// TODO: - Better date picker view
struct CreateCourseView: View {
    @Binding var courses: Array<CourseDto>?
    
    @State private var name = ""
    @State private var instructor = ""
    @State private var selectedDays = Set<String>()
    @State private var emailInput = ""
    @State private var emails = Array<String>()
    @State private var showingAlert = false
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 7)
    @State private var calendarWeekdaySymbols = Calendar.autoupdatingCurrent.shortWeekdaySymbols
    
    var isFormValid: Bool {
        !name.isEmpty && !instructor.isEmpty && !selectedDays.isEmpty && startDate < endDate
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            // MARK: - Course Details
            Section(header: Text("Course Details")) {
                TextField("Course Name", text: $name)
                TextField("Instructor", text: $instructor)
            }
            
            // MARK: - Days Selection
            Section(header: Text("Repeat On")) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 7)],alignment: .center, spacing: 12) {
                    ForEach(calendarWeekdaySymbols, id: \.self) { weekday in
                        let isSelected = selectedDays.contains(weekday)
                        Text(weekday)
                            .font(.subheadline).bold()
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
            }
            
            // MARK: - Date Selection
            Section(header: Text("Course Dates")) {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            
            // MARK: - Invite Students
            Section(header: Text("Invite Students")) {
                HStack {
                    TextField("Enter email", text: $emailInput)
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
                                        let newCourse = try await OAuthManager.shared.dbCommunicationServices?.createCourse(
                                            name: name,
                                            instructor: instructor,
                                            swiftShortSymbols: selectedDays,
                                            students: Set(emails),
                                            startDateISO: startDate.ISO8601Format(),
                                            endDateISO: endDate.ISO8601Format()
                                        )
                
                                        if let newCourse = newCourse {
                                            if var currentCourses = courses {
                                                currentCourses.append(newCourse)
                                                courses = currentCourses
                                            } else {
                                                courses = [newCourse]
                                            }
                                        } else {
                                            throw NSError(domain: "", code: 0, userInfo: nil)
                                        }
                
                                        self.presentationMode.wrappedValue.dismiss()
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
