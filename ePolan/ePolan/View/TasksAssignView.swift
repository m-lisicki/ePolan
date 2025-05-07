//
//  TasksDetailView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
@preconcurrency import Shared

struct TasksAssignView: View {
    @State private var isEditing: EditMode = .active
    
    let title: String
    let lessonId: KotlinUuid
    
    @State var exercises: Array<ExerciseDto>
    @State var declarations: Set<DeclarationDto>?
    
    @State var selection: Set<ExerciseDto> = []
    @State var initialSelection: Set<ExerciseDto> = []
    
    @State var savingError = false
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        VStack {
            if declarations != nil {
                List(exercises, id: \.self, selection: $selection) { exercise in
                    HStack {
                        Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                    }
                }
                .environment(\.editMode, $isEditing)
                .overlay {
                    if exercises.isEmpty {
                        ContentUnavailableView("No exercises", systemImage: "pencil.and.list.clipboard")
                    }
                }
            } else {
                VStack {
                    Image(systemName: "slowmo")
                        .symbolEffect(.variableColor.iterative.hideInactiveLayers.nonReversing, options: .repeat(.continuous))
                        .imageScale(.large)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
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
        }
        .task {
            //await fetchData()
        }
        .onChange(of: networkMonitor.isConnected) {
            Task {
                //await fetchData()
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
    
    private func fetchData() async {
        declarations = try? await dbQuery { try await $0.getAllLessonDeclarations(lessonId: lessonId) }
        selection = Set(declarations?.filter { $0.declarationStatus == DeclarationStatus.waiting }.compactMap(\.exercise) ?? [])
        
        initialSelection = selection
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
        declarations = try? await dbQuery { try await $0.getAllLessonDeclarations(lessonId: lessonId) }
    }
    
    
    private func postExerciseDeclaration(exerciseId: KotlinUuid) async {
        let result = try? await dbQuery { try await $0.postDeclaration(exerciseId: exerciseId) }
        if result == 200 {
            savingError = false
        } else {
            savingError = true
            return
        }
        declarations = try? await dbQuery { try await $0.getAllLessonDeclarations(lessonId: lessonId) }
    }
}
