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
    @State private var isEditing = true
    
    let title: String
    let lesson: LessonDto
    
    @State var exercises: Array<ExerciseDto>
    @State var declarations: Set<DeclarationDto>?
    
    @State var selection: Set<ExerciseDto>?
    @State var initialSelection: Set<ExerciseDto>?
    
    @State var savingError = false
    
    var body: some View {
        VStack {
            if declarations != nil {
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
                Image(systemName: "exclamationmark")
                    .symbolRenderingMode(.multicolor)
                    .imageScale(.large)
                Text("Failed to fetch declarations")
            }
        }
        .toolbar {
            Button("Save") {
                let added = selection?.subtracting(initialSelection ?? []) ?? []
                let removed = initialSelection?.subtracting(selection ?? []) ?? []
                
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        for exercise in added {
                            group.addTask {
                                await postExerciseDeclaration(exerciseId: exercise.id)
                            }
                        }
               
                        for exercise in removed {
                            let matchingDeclarations = declarations?.filter { $0.exercise == exercise && $0.declarationStatus == DeclarationStatus.waiting}
                            if let matchingDeclarations = matchingDeclarations {
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
                guard let service = OAuthManager.shared.dbCommunicationServices else {
                    throw NSError(domain: "", code: 0, userInfo: nil)
                }
                
                declarations = try await service.getAllLessonDeclarations(lessonId: lesson.id)
                selection = Set(declarations!.filter { $0.declarationStatus == DeclarationStatus.waiting }.compactMap { $0.exercise })
                
                initialSelection = selection
            } catch {
                log.error("Database communication service is unavailable")
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
        let result = try? await OAuthManager.shared.dbCommunicationServices?.postUnDeclaration(declarationId: declarationId)
        if result == 200 {
            savingError = false
        } else {
            savingError = true
        }
        declarations = try? await OAuthManager.shared.dbCommunicationServices?.getAllLessonDeclarations(lessonId: lesson.id)
    }
    
    
    private func postExerciseDeclaration(exerciseId: KotlinUuid) async {
        let result = try? await OAuthManager.shared.dbCommunicationServices?.postDeclaration(exerciseId: exerciseId)
        if result == 200 {
            savingError = false
        } else {
            savingError = true
        }
        declarations = try? await OAuthManager.shared.dbCommunicationServices?.getAllLessonDeclarations(lessonId: lesson.id)
    }
}
