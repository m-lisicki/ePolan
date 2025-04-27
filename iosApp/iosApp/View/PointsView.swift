//
//  PointsView.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

struct PointsView: View {
    @State var lessons = [
        Lesson(id: 0, lessonName: "Introduction to SwiftUI", tasks: nil, deadline: Date(timeIntervalSinceNow: -2 * 60 * 60)),
        Lesson(id: 1, lessonName: "Creating Custom Views", tasks: [Task(assigned: true, number: 2, numberAddon: "a", taken: 9), Task(assigned: false, number: 3, numberAddon: nil, taken: 0), Task(assigned: true, number: 4, numberAddon: nil, taken: 4)], deadline: Date(timeIntervalSinceNow: 2 * 60 * 60)),
        Lesson(id: 2, lessonName: "Advanced Layout", tasks: nil, deadline: Date(timeIntervalSinceNow: 4 * 60 * 60)),
        Lesson(id: 3, lessonName: "Integrating with APIs", tasks: [Task(assigned: true, number: 1, numberAddon: nil, taken: 10), Task(assigned: false, number: 2, numberAddon: nil, taken: 0), Task(assigned: true, number: 3, numberAddon: nil, taken: 3)], deadline: Date(timeIntervalSinceNow: -6 * 60 * 60))
        
    ]
    
    var filteredLessons: [Lesson] {
        if searchText.isEmpty {
            return lessons
        } else {
            return lessons.filter { $0.lessonName.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    enum status: String {
        case upcoming = "Upcoming"
        case ongoing = "Ongoing"
    }
    
    @State var searchText: String = ""
    
    var body: some View {
        VStack {
            NavigationStack {
                let groupedLessons = Dictionary(grouping: filteredLessons) { lesson in
                    lesson.deadline > Date() ? status.upcoming.rawValue : status.ongoing.rawValue
                }
                
                List {
                    ForEach(groupedLessons.keys.sorted(), id: \.self) { key in
                        Section(header: Text(key)) {
                            ForEach(groupedLessons[key] ?? []) { lesson in
                                if let lessonTasks = lesson.tasks {
                                    if key == status.ongoing.rawValue {
                                        NavigationLink(destination: TasksAssignedView(title: lesson.lessonName,tasks: lessonTasks)) {
                                            Text(lesson.lessonName)
                                                .font(.headline)
                                        }
                                    } else {
                                        NavigationLink(destination: TasksDetailView(tasks: lessonTasks, name: lesson.lessonName, selection: $lessons[lesson.id].selection)) {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(lesson.lessonName)
                                                        .font(.headline)
                                                }
                                                Spacer()
                                                Text("\(lesson.selection.count)/\(lesson.tasks?.count ?? 0)")
                                            }
                                        }
                                    }
                                } else {
                                    Text(lesson.lessonName)
                                        .font(.headline)
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
}
