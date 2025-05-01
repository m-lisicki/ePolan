//
//  TasksDetailView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

struct TasksDetailView: View {
    @State private var isEditing = true
    
    let title: String
    let lesson: LessonDto
    
    @State var exercises: Array<ExerciseDto>?
    @State var declarations: Set<DeclarationDto>?
    
    @State var selection: Set<ExerciseDto>
    
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
        .onChange(of: selection) { oldSelection, newSelection in
            
            let added = newSelection.subtracting(oldSelection)
            let removed = oldSelection.subtracting(newSelection)

            for exercise in added {
                postExerciseDeclaration(exerciseId: exercise.id)
            }

            for exercise in removed {
                let matchingDeclarations = declarations?.filter { $0.exercise == exercise && $0.declarationStatus == DeclarationStatus.waiting}
                if let matchingDeclarations = matchingDeclarations {
                    for declaration in matchingDeclarations {
                        postExerciseUnDeclaration(declarationId: declaration.id)
                    }
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            if savingError {
                Text("Save failed")
            }
        }
    }
        
    private func postExerciseUnDeclaration(declarationId: KotlinUuid) {
        Task {
            let result = try await OAuthManager.shared.dbCommunicationServices?.postUnDeclaration(declarationId: declarationId)
            if result == 200 {
                savingError = false
            } else {
                savingError = true
            }
            declarations = try await OAuthManager.shared.dbCommunicationServices?.getAllLessonDeclarations(lessonId: lesson.id)
        }
    }
    
    
    private func postExerciseDeclaration(exerciseId: KotlinUuid) {
        Task {
            let result = try await OAuthManager.shared.dbCommunicationServices?.postDeclaration(exerciseId: exerciseId)
            if result == 200 {
                savingError = false
            } else {
                savingError = true
            }
            declarations = try await OAuthManager.shared.dbCommunicationServices?.getAllLessonDeclarations(lessonId: lesson.id)
        }
    }
}
