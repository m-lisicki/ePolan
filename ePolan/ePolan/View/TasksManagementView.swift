//
//  TasksManagementView.swift
//  iosApp
//
//  Created by Michał Lisicki on 02/05/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

struct TasksManagementView: View {
    @State var lesson: LessonDto
    @State var exercises: Set<ExerciseDto>
    
    @Environment(RefreshController.self) var refreshController
    @Environment(\.dismiss) private var dismiss
        
    var body: some View {
        VStack {
            if !exercises.isEmpty {
                List(exercises.sortedByNumber(), id: \.id) { exercise in
                    HStack {
                        Text("\(exercise.exerciseNumber). \(exercise.subpoint ?? "")")
                        Spacer()
                        let siblings = exercises.filter {$0.exerciseNumber == exercise.exerciseNumber}
                        let sortedSiblings = siblings.sorted { ($0.subpoint ?? "") < ($1.subpoint ?? "") }
                        
                        if siblings.count == 1 || sortedSiblings.last?.id == exercise.id {
                            HStack {
                                let isOnlyBaseLast = siblings.count == 1 && exercise.exerciseNumber == (exercises.map { $0.exerciseNumber }.max() ?? Int32.min)
                                if siblings.count > 1 || isOnlyBaseLast {
                                    Button { removeExercise(for: exercise)} label: {
                                        Image(systemName: "minus.diamond.fill")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                Button { addSubpoint(to: exercise)} label: {
                                    Image(systemName: "plus.diamond.fill")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
            } else {
                Text("No exercises yet")
            }
            Button("Add exercise") {
                addExercise()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Manage exercises")
        .toolbar {
            Button("Save") {
                    lesson = LessonDto(id: lesson.id, classDate: lesson.classDate, courseName: lesson.courseName, exercises: exercises, lessonStatus: lesson.lessonStatus)
                    
                    Task {
                        try await dbQuery {
                            try await $0.postExercises(lesson: lesson)
                        }
                    }
                    refreshController.triggerRefreshExercises()
                    
            }
            .disabled(lesson.exercises == exercises)
        }
    }
    
    private func addExercise() {
        let index = (exercises.map(\.exerciseNumber).max() ?? 0) + 1
        exercises = exercises.union([ExerciseDto(classDate: lesson.classDate, groupName: lesson.courseName, exerciseNumber: Int32(index), subpoint: nil)])
    }
    
    private func addSubpoint(to exercise: ExerciseDto) {
        var set = exercises
        
        let siblings = set.filter { $0.exerciseNumber == exercise.exerciseNumber }
        
        if exercise.subpoint == nil {
            // First subpoint (creating a and b at once)
            let first = exercise
            set.remove(first)
            first.subpoint = "a"
            set.insert(first)
            let second = ExerciseDto(classDate: exercise.classDate, groupName: exercise.groupName, exerciseNumber:  exercise.exerciseNumber, subpoint: "b")
            set.insert(second)
            exercises = set
            return
        }
        
        let sortedSiblings = siblings.sorted { ($0.subpoint ?? "") < ($1.subpoint ?? "") }
        
        if let last = sortedSiblings.last, let lastSubpoint = last.subpoint {
            var nextSubpoint: String?

            if let ascii = lastSubpoint.unicodeScalars.first?.value, ascii < 122 {
                nextSubpoint = String(Character(UnicodeScalar(ascii + 1)!))
            } else if lastSubpoint.starts(with: "z") {
                let apostropheCount = lastSubpoint.dropFirst().filter { $0 == "'" }.count
                nextSubpoint = "z" + String(repeating: "'", count: apostropheCount + 1)
            }

            if let nextSubpoint {
                let next = ExerciseDto(
                    classDate: exercise.classDate,
                    groupName: exercise.groupName,
                    exerciseNumber: exercise.exerciseNumber,
                    subpoint: nextSubpoint
                )
                set.insert(next)
            }
        }
        
        exercises = set
    }
        
    
    
    private func removeExercise(for exercise: ExerciseDto) {
        var set = exercises
        
        set.remove(exercise)
        
        let siblings = set.filter { $0.exerciseNumber == exercise.exerciseNumber }
        
        // Last subpoints - converting back to exercise without subpoint
        if siblings.count == 1, let second = siblings.first, second.subpoint != nil {
            set.remove(second)
            second.subpoint = nil
            set.insert(second)
        }
        
        exercises = set
    }
}
