//
//  TasksAssignedView.swift
//  iosApp
//
//  Created by Michał Lisicki on 30/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

struct TasksAssignedView: View {
    let title: String
    let lesson: LessonDto
    @State var exercises: Array<ExerciseDto>?
    @State var declarations: Set<DeclarationDto>?
    @State var activity: Double = 0
    
    @State var sheetIsPresented: Bool = false
    @EnvironmentObject var refreshController: RefreshController
    
    var body: some View {
        VStack {
            if let exercises = exercises {
                List(exercises, id: \.id) { exercise in
                    HStack {
                        Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
                        Spacer()
                        Text(declarations?.contains(where: { $0.exercise == exercise && $0.declarationStatus == DeclarationStatus.approved }) ?? false ? "Assigned 🎉" : "Not assigned")
                    }
                }
                .refreshable {
                    Task {
                        await fetchData()
                    }
                }
                Stepper("Points: \(String(format: "%.2f", activity))", value: $activity, in: 0...5, step: 0.5)
                    .padding()
            } else {
                Text("No exercises")
            }
        }
        //TODO: - Add throwing errors
        .onDisappear {
            Task {
                if let email = OAuthManager.shared.email {
                    try await OAuthManager.shared.dbCommunicationServices?.addPoints(student: email, lesson: lesson, activityValue: activity)
                }
                refreshController.triggerRefresh()
            }
        }
        .task {
                await fetchData()
        }
        .navigationTitle(title)
    }
    
    private func fetchData() async {
        declarations = try? await OAuthManager.shared.dbCommunicationServices?.getAllLessonDeclarations(lessonId: lesson.id)
    }
}
