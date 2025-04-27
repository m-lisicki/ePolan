import SwiftUI
//import Shared

struct ContentView: View {
#if !RELEASE
    @EnvironmentObject var oauth: OAuthManager
#endif
    
    var body: some View {
#if !RELEASE
        if oauth.authState == nil {
            SignInView()
        } else {
            BottomBarView()
        }
#else
        BottomBarView()
#endif
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
}

struct BottomBarView: View {
    var body: some View {
        TabView {
            PointsView()
                .tabItem {
                    Label("Points", systemImage: "star")
                }
            UserManagementView()
                .tabItem {
                    Label("User", systemImage: "person.crop.circle")
                }
        }
    }
}

struct Lesson: Identifiable {
    let id: Int
    
    let lessonName: String
    
    let tasks: [Task]?
    let deadline: Date
    
    var selection = Set<UUID>()
}


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

struct Task: Identifiable, Hashable {
    var id = UUID()
    
    var assigned: Bool
    var number: Int
    var numberAddon: String?
    var taken: Int
}

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

struct UserManagementView: View {
    @EnvironmentObject private var oauth: OAuthManager
    
    var body: some View {
        VStack {
            Button("Logout") {
                oauth.logout()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
