//
//  TasksAssignedView.swift
//  ePolan
//
//  Created by Michał Lisicki on 30/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Combine
import ConfettiSwiftUI

#Preview {
    TasksAssignedView(title: "Get Back!", lesson: LessonDto.getMockData().first!, activity: 0.0)
        .environment(OAuthManager.shared)
        .environment(NetworkMonitor())
        .environment(RefreshController())
}

struct TasksAssignedView: View {
    let title: String
    let lesson: LessonDto
    @State var declarations = Set<DeclarationDto>()
    @State var activity: Double
    
    @State var activityTask: Task<Void, Never>?
    @State var savingError = false
    
    @State var confetti = false
    
    @Environment(RefreshController.self) var refreshController
    
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    var body: some View {
        VStack {
            List(lesson.exercises.sortedByNumber(), id: \.id) { exercise in
                HStack {
                    Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                    Spacer()
                    Text(declarations.contains(where: { $0.exercise == exercise && $0.declarationStatus == .approved }) ? "Assigned 🎉" : "Not assigned")
                }
            }
            .refreshable {
                await fetchData()
            }.overlay {
                if lesson.exercises.isEmpty {
                    ContentUnavailableView("No exercises", systemImage: "pencil.and.list.clipboard")
                } else if declarations.isEmpty {
                    ContentUnavailableView("No declarations", systemImage: "person.fill")
                }
            }
            .confettiCannon(trigger: $confetti)
            Stepper("Points: \(String(format: "%.2f", activity))", value: Binding<Double>(get:{self.activity},set:{self.activity = $0}), in: 0...5, step: 0.5)
                .padding()
        }
        .onChange(of: declarations) {
            if declarations.first(where: { $0.declarationStatus == .approved }) != nil {
                confetti.toggle()
            }
        }
        .onChange(of: activity) { oldValue, newValue in
            activityTask?.cancel()
            activityTask = Task {
                try? await Task.sleep(for: .seconds(1))
                
                if Task.isCancelled { return }
                
                do {
                    try await DBQuery.addPoints(lessonId: lesson.id, activityValue: newValue)
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
#if !targetEnvironment(simulator)
        let declarations = try? await DBQuery.getAllLessonDeclarations(lessonId: lesson.id, forceRefresh: forceRefresh)
        if let declarations = declarations {
            self.declarations = declarations
        }
#else
        declarations = Set(DeclarationDto.getMockData())
#endif
    }
}
