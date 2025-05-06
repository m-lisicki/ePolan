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
    
    var body: some View {
        VStack {
            if let declarations = declarations {
                if !exercises.isEmpty {
                    List(exercises, id: \.id) { exercise in
                        HStack {
                            Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                            Spacer()
                            Text(declarations.contains(where: { $0.exercise == exercise && $0.declarationStatus == DeclarationStatus.approved }) ? "Assigned 🎉" : "Not assigned")
                        }
                    }
                    .refreshable {
                        await fetchData()
                    }
                } else {
                    Image(systemName: "pencil.and.list.clipboard")
                        .symbolRenderingMode(.palette)
                        .imageScale(.large)
                    Text("No exercises")
                }
            } else {
                Image(systemName: "exclamationmark")
                    .symbolRenderingMode(.multicolor)
                    .imageScale(.large)
                Text("Failed to fetch declarations")
            }
            Stepper("Points: \(String(format: "%.2f", activity))", value: Binding<Double>(get:{self.activity},set:{self.activity = $0}), in: 0...5, step: 0.5)
                .padding()
        }
        .onChange(of: activity) { oldValue, newValue in
            activityTask?.cancel()
            activityTask = Task {
                try? await Task.sleep(for: .seconds(2))

                if Task.isCancelled { return }

                if let email = ePolan.OAuthManager.shared.email {
                    do {
                        try await OAuthManager.shared.dbCommunicationServices?.addPoints(student: email, lesson: lesson, activityValue: newValue)
                    } catch {
                        savingError = true
                    }
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
        .navigationTitle(title)
    }
    
    private func fetchData() async
        OAuthManager.shared.performActionWithFreshTokens()
        declarations = try? await OAuthManager.shared.dbCommunicationServices?.getAllLessonDeclarations(lessonId: lesson.id)
    }
}
