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

struct CreateCourseView: View {
    @State private var name = ""
    @State private var instructor = ""
    @State private var selectedDays = Set<Day>()
    
    var isFormValid: Bool {
        !name.isEmpty && !instructor.isEmpty && !selectedDays.isEmpty
    }
    
    @State private var emailInput = ""
    
    var trimmed: String { emailInput.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    @State private var emails: [String] = []
    
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
                    emails.append(trimmed)
                    emailInput = ""
                }
                .disabled(!CreateCourseView.isValidEmail(trimmed) || trimmed.isEmpty)
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
                
                //TODO: - Broken due to Kotlin implementation
                /*
                Task {
                    do {
                        try await postsService.createCourse(
                            name: name,
                            instructor: instructor,
                            lessonTimeDtos: lessonTimeDtos
                        )
                    } catch {
                        log.error("\(error)")
                    }
                }*/
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid)
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .navigationTitle("Create Course")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    static private func isValidEmail(_ email: String) -> Bool {
        return email.range(of: #"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$"#, options: .regularExpression) != nil
    }
}
