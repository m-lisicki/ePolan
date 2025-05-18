//
//  TasksDetailView.swift
//  ePolan
//
//  Created by Michał Lisicki on 27/04/2025.
//

import SwiftUI

struct TasksAssignView: View, FallbackView, PostData {
    typealias T = ExerciseDto
    
    @State var isEditing: EditMode = .active
    @State var isPutOngoing = false
    
    let title: String
    let lessonId: UUID
    
    @State var data: Set<ExerciseDto>? {
        didSet {
            if let data = data {
                exercises = data.sortedByNumber()
            }
        }
    }
    
    @State var exercises = Array<ExerciseDto>()
    
    @State var declarations: Set<DeclarationDto>?
    @State var selection: Set<ExerciseDto> = []
    @State var initialSelection: Set<ExerciseDto> = []
        
    @Environment(\.dismiss) var dismiss
    
    @Environment(NetworkMonitor.self) var networkMonitor
    
    @State var showApiError: Bool = false
    @State var apiError: ApiError?
    
    var body: some View {
        VStack {
                List(exercises, id: \.self, selection: $selection) { exercise in
                    HStack {
                        Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                    }
                }
                .environment(\.editMode, $isEditing)
                .fallbackView(viewState: viewState)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    isPutOngoing = true
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
                                let matchingDeclarations = declarations?.filter({ $0.exercise == exercise && $0.declarationStatus == .waiting}) ?? []
                                for declaration in matchingDeclarations {
                                    group.addTask {
                                        await postExerciseUnDeclaration(declarationId: declaration.id)
                                    }
                                }
                            }
                        }
                    }
                    
                    initialSelection = selection
                    isPutOngoing = false
                    dismiss()
                }
                .replacedWithProgressView(isPutOngoing: isPutOngoing)
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
    
    func fetchData(forceRefresh: Bool = false) async {
        await fetchData(
            forceRefresh: forceRefresh,
            fetchOperation: { try await DBQuery.getAllLessonDeclarations(lessonId: lessonId) },
            onError: { error in self.apiError = error }
        ) {
            newDeclarations in
#if !targetEnvironment(simulator)
            self.declarations = newDeclarations
#else
            declarations = Set(DeclarationDto.getMockData())
#endif
            selection = Set(newDeclarations.filter { $0.declarationStatus == .waiting }.compactMap(\.exercise))
            initialSelection = selection
        }
    }
    
    func postExerciseUnDeclaration(declarationId: UUID) async {
        await postInformation(
            postOperation: { try await DBQuery.removeDeclaration(declarationId: declarationId) },
            onError: { error in self.apiError = error }
        ) {
            if let item = declarations?.first(where: { $0.id == declarationId }) {
                declarations?.remove(item)
            }
        }
    }
    
    
    func postExerciseDeclaration(exerciseId: UUID) async {
        await postInformation(
            postOperation: { try await DBQuery.postDeclaration(exerciseId: exerciseId) },
            onError: { error in self.apiError = error }
        ) {
            Task {
                await fetchData()
            }
        }
    }
}
