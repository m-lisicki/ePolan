//
//  TasksDetailView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

// TODO: - Fetch real ongoing declarations selection and exercises
struct TasksDetailView: View {
    @State private var isEditing = true
    
    let title: String
    let lesson: LessonDto
    
    @State var exercises: Array<ExerciseDto>?
    @State var declarations: Set<DeclarationDto>?
    
    @State var selection = Set<ExerciseDto>()
    
    @State var savingError = false
    
    var body: some View {
        VStack {
            if let exercises = exercises {
                List(exercises, id: \.self, selection: $selection) { exercise in
                    HStack {
                        Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                    }
                }
                .onAppear {
                    isEditing = true
                }
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            } else {
                Text("No exercises")
            }
        }
        .onChange(of: selection) { old, new in
            if old.count < new.count {
                new.subtracting(old).forEach { exercise in postExerciseDeclaration(exerciseID: exercise.id) }
            } else {
                old.subtracting(new).forEach { exercise in postExerciseUnDeclaration(exerciseID: exercise.id) }
            }
        }
        .onAppear {
            Task {
                exercises = try await OAuthManager.shared.dbCommunicationServices?.getAllExercises(lessonId: lesson.id)
                declarations = try await OAuthManager.shared.dbCommunicationServices?.getAllLessonDeclarations(lessonId: lesson.id)
                print(exercises?.compactMap { $0.id } ?? "nothing")
            }
            if let declarations = declarations {
                selection = Set(declarations.filter { $0.declarationStatus == DeclarationStatus.waiting }.compactMap { $0.exercise })
            }
        }
        .navigationTitle(title)
        .toolbar {
            if savingError {
                Text("Save failed")
            }
        }
    }
    
    // TODO: - POST for deleting declaration
    
    private func postExerciseUnDeclaration(exerciseID: KotlinUuid) {
        Task {
            let result = try await OAuthManager.shared.dbCommunicationServices?.postUnDeclaration(exerciseId: exerciseID)
            if result == 200 {
                savingError = false
            } else {
                savingError = true
            }
        }
    }
    
    
    private func postExerciseDeclaration(exerciseID: KotlinUuid) {
        Task {
            let result = try await OAuthManager.shared.dbCommunicationServices?.postDeclaration(exerciseId: exerciseID)
            if result == 200 {
                savingError = false
            } else {
                savingError = true
            }
        }
    }
}

// TODO: - Fetch points, and add controler to add them to lesson
struct TasksAssignedView: View {
    let title: String
    let lesson: LessonDto
    @State var exercises: Array<ExerciseDto>?
    @State var declarations: Set<DeclarationDto>?
    @State var points: Int = 0
    
    @State var sheetIsPresented: Bool = false
    
    var body: some View {
        VStack {
            if let exercises = exercises {
                List(exercises, id: \.id) { exercise in
                    HStack {
                        Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                        Spacer()
                        Text(declarations?.contains(where: { $0.exercise == exercise && $0.declarationStatus == DeclarationStatus.approved }) ?? false ? "Assigned 🎉" : "Not assigned")
                    }
                }
            } else {
                Text("No exercises")
            }
        }
        .toolbar {
            Button(action: { sheetIsPresented = true } ) {
                Image(systemName: "plus.forwardslash.minus")
            }
        }
        .onAppear {
            Task {
                exercises = try await OAuthManager.shared.dbCommunicationServices?.getAllExercises(lessonId: lesson.id)
                declarations = try await OAuthManager.shared.dbCommunicationServices?.getAllLessonDeclarations(lessonId: lesson.id)
                
            }
        }
        .navigationTitle(title)
    }
}
