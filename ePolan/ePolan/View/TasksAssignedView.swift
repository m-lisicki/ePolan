//
//  TasksAssignedView.swift
//  ePolan
//
//  Created by Michał Lisicki on 30/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
@preconcurrency import Shared
import Combine

struct TasksAssignedView: View {
    let title: String
    let lessonId: KotlinUuid
    @State var exercises: Array<ExerciseDto>
    @State var declarations = Set<DeclarationDto>()
    @State var activity: Double
    
    @State var activityTask: Task<Void, Never>?
    @State var savingError = false
    
    @Environment(DeclarationsCache.self) var declarationsCache
    
    @Environment(RefreshController.self) var refreshController
    
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        VStack {
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
                        } else if declarations.isEmpty {
                            ContentUnavailableView("No declarations", systemImage: "person.fill")
                        }
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
                        try await $0.addPoints(lessonId: lessonId, activityValue: newValue)
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
    
    private func fetchData(forceRefresh: Bool = false) async {
        if !forceRefresh, let declarationsCache = declarationsCache.loadCachedDeclarations(id: lessonId) {
            declarations = declarationsCache
            return
        }
        
        let declarations = try? await dbQuery { try await $0.getAllLessonDeclarations(lessonId: lessonId) }
        if let declarations = declarations {
            self.declarations = declarations
            declarationsCache.addDeclarationsToCache(id: lessonId, declarations)
        }
    }
}
