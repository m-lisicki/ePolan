//
//  TasksDetailView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

struct TasksAssignView: View, FallbackView {
    typealias T = DeclarationDto
    
    @State private var isEditing: EditMode = .active
    
    let title: String
    let lessonId: UUID
    
    @State var exercises: Array<ExerciseDto>
    @State var data: Set<DeclarationDto>?
        
    @State var selection: Set<ExerciseDto> = []
    @State var initialSelection: Set<ExerciseDto> = []
        
    @Environment(\.dismiss) private var dismiss
    
    @Environment(NetworkMonitor.self) var networkMonitor
    
    @State var showApiError: Bool = false
    @State var apiError: ApiError? {
        didSet {
            if networkMonitor.isConnected {
                showApiError = true
            }
        }
    }
    
    var body: some View {
        VStack {
                List(exercises, id: \.self, selection: $selection) { exercise in
                    HStack {
                        Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                    }
                }
                .environment(\.editMode, $isEditing)
                .fallbackView(viewState: viewState, fetchData: fetchData)
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
                                let matchingDeclarations = data?.filter({ $0.exercise == exercise && $0.declarationStatus == .waiting}) ?? []
                                for declaration in matchingDeclarations {
                                    group.addTask {
                                        await postExerciseUnDeclaration(declarationId: declaration.id)
                                    }
                                }
                            }
                        }
                    }
                    
                    initialSelection = selection
                    
                    dismiss()
                }
                .disabled(initialSelection == selection)
            }
        }
        .task {
            await fetchData()
        }
        .onChange(of: networkMonitor.isConnected) {
            Task {
                await fetchData()
            }
        }
        .navigationTitle(title)
    }
    
    private func fetchData(forceRefresh: Bool = false) async {
        do {
#if !targetEnvironment(simulator)
            data = try await DBQuery.getAllLessonDeclarations(lessonId: lessonId)
#else
            data = Set(DeclarationDto.getMockData())
#endif
            selection = Set(data?.filter { $0.declarationStatus == .waiting }.compactMap(\.exercise) ?? [])
            
            initialSelection = selection
            
            apiError = nil
        } catch {
            apiError = error.mapToApiError()
        }
    }
    
    private func postExerciseUnDeclaration(declarationId: UUID) async {
        do {
            try await DBQuery.removeDeclaration(declarationId: declarationId)
            if let item = data?.first(where: { $0.id == declarationId }) {
                data?.remove(item)
            }
        } catch {
            apiError = error.mapToApiError()
        }
    }
    
    
    private func postExerciseDeclaration(exerciseId: UUID) async {
        do {
            try await DBQuery.postDeclaration(exerciseId: exerciseId)
        } catch {
            apiError = error.mapToApiError()
        }
        
        await fetchData()
    }
}
