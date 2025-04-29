//
//  Day.swift
//  iosApp
//
//  Created by Michał Lisicki on 28/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

enum Day: Int, CaseIterable {
    case sunday    = 1
    case monday    = 2
    case tuesday   = 3
    case wednesday = 4
    case thursday  = 5
    case friday    = 6
    case saturday  = 7
    
    var firstLetter: String {
        String(String(describing: self).prefix(1)).uppercased()
    }
}

#Preview {
    ContentView()
}

// TODO: - Better date picker view
struct CreateCourseView: View {
    @Binding var courses: Array<CourseDto>?
    
    @State private var name = ""
    @State private var instructor = ""
    @State private var selectedDays = Set<Day>()
    
    var isFormValid: Bool {
        !name.isEmpty && !instructor.isEmpty && !selectedDays.isEmpty
    }
    
    @State private var emailInput = ""
        
    @State private var emails = Array<String>()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Course Name", text: $name)
            TextField("Instructor", text: $instructor)
            
            HStack {
                ForEach(Day.allCases, id: \.self) { day in
                    Text(day.firstLetter)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            selectedDays.contains(day)
                            ? Color.accentColor.cornerRadius(10)
                            : Color.gray.cornerRadius(10)
                        )
                        .onTapGesture {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                }
            }
            
            HStack {
                TextField("Enter email", text: $emailInput)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button("Add") {
                    emails.append(EmailHelper.trimCharacters(emailInput))
                    emailInput = ""
                }
                .disabled(!EmailHelper.isEmailValid(emailInput))
                .buttonStyle(.bordered)
            }
            
            List(emails, id: \.self) { email in
                Text(email)
            }
            .listStyle(.plain)
            
            
            Button("Done") {
                let lessonTimeDtos: Set<LessonTimeDto> = selectedDays.map {
                    LessonTimeDto(dayOfWeek: Int32($0.rawValue), hour: 0, minute: 0)
                }.reduce(into: []) { $0.insert($1) }
                
                Task {
                    do {
                        let newCourse = try await OAuthManager.shared.dbCommunicationServices?.createCourse(
                            name: name,
                            instructor: instructor,
                            lessonTimeDtos: lessonTimeDtos,
                            students: Set(emails)
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
                        alertMessage = "An unexpected error occurred while creating the course"
                        showingAlert = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid)
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .navigationTitle("Create Course")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
    }
    
}

struct EmailHelper {
    static func trimCharacters(_ email: String) -> String {
        return email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func isEmailValid(_ email: String) -> Bool {
        let email = trimCharacters(email)
        return !email.isEmpty && email.range(of: #"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$"#, options: .regularExpression) != nil
    }
}
