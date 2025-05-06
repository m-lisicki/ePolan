//
//  TasksDetailView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

struct TasksAssignView: View {
    @State private var isEditing: EditMode = .active
    
    let title: String
    let lesson: LessonDto
    
    @State var exercises: Array<ExerciseDto>
    @State var declarations: Set<DeclarationDto>?
    
    @State var selection: Set<ExerciseDto> = []
    @State var initialSelection: Set<ExerciseDto> = []
    
    @State var savingError = false
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            if declarations != nil {
                List(exercises, id: \.self, selection: $selection) { exercise in
                    HStack {
                        Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                    }
                }
                .environment(\.editMode, $isEditing)
            } else {
                Image(systemName: "exclamationmark")
                    .symbolRenderingMode(.multicolor)
                    .imageScale(.large)
                Text("Failed to fetch declarations")
            }
        }
        .toolbar {
            Button("Save") {
                let added = selection.subtracting(initialSelection)
                let removed = initialSelection.subtracting(selection)
                
                Task {
                    await withTaskGroup { group in
                        for exercise in added {
                            group.addTask {
                                await postExerciseDeclaration(exerciseId: exercise.id)
                            }
                        }
               
                        for exercise in removed {
                            if let matchingDeclarations = declarations?.filter({ $0.exercise == exercise && $0.declarationStatus == DeclarationStatus.waiting}) {
                                for declaration in matchingDeclarations {
                                    group.addTask {
                                        await postExerciseUnDeclaration(declarationId: declaration.id)
                                    }
                                }
                            }
                        }
                    }
                }
                
                initialSelection = selection
            }
            .disabled(initialSelection == selection)
        }
        .task {
            do {
                
                declarations = try await dbQuery { try await $0.getAllLessonDeclarations(lessonId: lesson.id) }
                selection = Set(declarations!.filter { $0.declarationStatus == DeclarationStatus.waiting }.compactMap(\.exercise))
                
                initialSelection = selection
            } catch {
                log.error("Database communication service is unavailable")
                dismiss()
            }
        }
        .alert(isPresented: $savingError) {
            Alert(
                title: Text("Saving error"),
                message: Text("Something went wrong. Try again later."),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle(title)
    }
    
    private func postExerciseUnDeclaration(declarationId: KotlinUuid) async {
        let result = try? await dbQuery {
            try await $0.postUnDeclaration(declarationId: declarationId)
        }
        if result == 200 {
            savingError = false
        } else {
            savingError = true
            return
        }
        declarations = try? await dbQuery { try await $0.getAllLessonDeclarations(lessonId: lesson.id) }
    }
    
    
    private func postExerciseDeclaration(exerciseId: KotlinUuid) async {
        let result = try? await dbQuery { try await $0.postDeclaration(exerciseId: exerciseId) }
        if result == 200 {
            savingError = false
        } else {
            savingError = true
            return
        }
        declarations = try? await dbQuery { try await $0.getAllLessonDeclarations(lessonId: lesson.id) }
    }
}
