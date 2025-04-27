//
//  TasksDetailView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

struct TasksDetailView: View {
    @State private var isEditing = false
    @State var tasks: [Task]
    let name: String
    @Binding var selection: Set<UUID>
    
    var body: some View {
        List(tasks, selection: $selection) { task in
            HStack {
                Text("\(task.number)\(task.numberAddon ?? "").")
            }
            .tag(task.id)
        }
        .onAppear {
            isEditing = true
        }
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .onChange(of: selection.count) { _, _ in
            updateTasksAssignment()
        }
        .navigationTitle(name)
    }
    
    private func updateTasksAssignment() {
        for index in tasks.indices {
            tasks[index].assigned = selection.contains(tasks[index].id)
        }
        
    }
}

struct TasksAssignedView: View {
    let title: String
    let tasks: [Task]
    
    var body: some View {
        List(tasks) { task in
            HStack {
                Text("\(task.number)\(task.numberAddon ?? "").")
                Spacer()
                Text(task.assigned ? "Assigned 🎉" : "Not assigned")
            }
        }
        .navigationTitle(title)
    }
}
