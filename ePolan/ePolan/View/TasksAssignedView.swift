//
//  TasksAssignedView.swift
//  iosApp
//
//  Created by Michał Lisicki on 30/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared
import Combine

struct TasksAssignedView: View {
    let title: String
    let lesson: LessonDto
    @State var exercises: Array<ExerciseDto>
    @State var declarations: Set<DeclarationDto>?
    @State var activity: Double
    
    @State var activityTask: Task<Void, Never>?
    @State var savingError = false
    
    @Environment(RefreshController.self) var refreshController
    
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        VStack {
            if let declarations = declarations {
                    List(exercises, id: \.id) { exercise in
                        HStack {
                            Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                            Spacer()
                            Text(declarations.contains(where: { $0.exercise == exercise && $0.declarationStatus == DeclarationStatus.approved }) ? "Assigned 🎉" : "Not assigned")
                        }
                    }
                    .refreshable {
                        await fetchData()
                    }.overlay {
                        if exercises.isEmpty {
                            ContentUnavailableView("No exercises", systemImage: "pencil.and.list.clipboard")
                        }
                    }
            } else {
                VStack {
                    Image(systemName: "slowmo")
                        .symbolEffect(.variableColor.iterative.hideInactiveLayers.nonReversing, options: .repeat(.continuous))
                        .imageScale(.large)
                }.padding()
            }
            Stepper("Points: \(String(format: "%.2f", activity))", value: Binding<Double>(get:{self.activity},set:{self.activity = $0}), in: 0...5, step: 0.5)
                .padding()
        }
        .onChange(of: activity) { oldValue, newValue in
            activityTask?.cancel()
            activityTask = Task {
                try? await Task.sleep(for: .seconds(1))
                
                if Task.isCancelled { return }
                
                do {
                    try await dbQuery {
                        try await $0.addPoints(lessonId: lesson.id, activityValue: newValue)
                    }
                    refreshController.refreshSignalActivity.send()
                } catch {
                    savingError = true
                }
                
            }
        }
        .alert(isPresented: $savingError) {
            Alert(
                title: Text("Saving error"),
                message: Text("Something went wrong. Try again later."),
                dismissButton: .default(Text("OK"))
            )
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
    
    private func fetchData() async {
        declarations = try? await dbQuery { try await $0.getAllLessonDeclarations(lessonId: lesson.id) }
    }
}
