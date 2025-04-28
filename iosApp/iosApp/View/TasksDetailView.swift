//
//  TasksDetailView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import Shared

// TODO: - Fetch real ongoing declarations selection
struct TasksDetailView: View {
    @State private var isEditing = false
    
    @State var exercises: [ExerciseDto]
    
    let name: String
    @State var selection: Set<UUID> = []
    
    var body: some View {
        List(exercises, id: \.id, selection: $selection) { exercise in
            HStack {
                Text("\(exercise.exerciseNumber)\(exercise.subpoint ?? "").")
            }
            .tag(exercise.id)
        }
        .onAppear {
            isEditing = true
        }
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .onChange(of: selection.count) { _, _ in
            postExerciseDeclaration()
        }
        .navigationTitle(name)
    }
    
    private func postExerciseDeclaration() {
        // TODO: - POST for updating declaration
    }
}

// TODO: - Fetch which tasks are assigned
struct TasksAssignedView: View {
    let title: String
    let tasks: Array<ExerciseDto>
    
    var body: some View {
            List(tasks, id: \.id) { task in
                HStack {
                    Text("\(task.id)\(task.subpoint ?? "").")
                    Spacer()
                    //Text(task.assigned ? "Assigned 🎉" : "Not assigned")
                }
            }
            .navigationTitle(title)
        }
}
